/**
 * Cloud Functions for DeliPuno (delypuno-ddd2d).
 *
 * autoDeleteExpiredOrders — scheduled cleanup that runs every 5 minutes and
 * permanently deletes orders that are either:
 *   A) cancelled more than 30 minutes ago, or
 *   B) never picked up by a courier and past their expiresAt timestamp.
 *
 * Round-robin courier assignment (Firestore-only, no FCM):
 *   offerOrderOnCreate    — onCreate: starts offering a brand-new order.
 *   offerOrderOnReleased  — onUpdate: offers to the next courier whenever an
 *                           order re-enters the "needs a courier" state (a
 *                           courier rejected / timed out, or an admin retried).
 *   reclaimExpiredOffers  — scheduled backstop (every 1 min) that releases
 *                           offers whose 30s window lapsed without the offered
 *                           courier's app responding (e.g. app was closed) and
 *                           re-offers any stranded order, so the round-robin
 *                           keeps rotating (calls offerToNextCourier directly).
 *   manualReassign        — HTTPS callable invoked by the admin "Reasignar"
 *                           button: resets the rotation and re-offers directly
 *                           (no reliance on the onUpdate trigger edge).
 *
 * Runs with the Firebase Admin SDK, so it bypasses Firestore security rules.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// How long a cancelled order is kept before deletion.
const CANCELLED_TTL_MS = 30 * 60 * 1000; // 30 minutes

// Statuses eligible for expiry deletion (Condition B): an order still waiting
// to be taken that passes its expiresAt is treated as abandoned and removed.
// These map to the spec's "pendiente" and "buscando_repartidor".
// Orders that are confirmed ("confirmado"), being prepared, already in a
// courier's hands (accepted/picked_up/en_camino) or finished (entregado) are
// NEVER deleted by Condition B.
const EXPIRY_ELIGIBLE_STATUSES = ["pending", "searching"];

const FieldPath = admin.firestore.FieldPath;
const Timestamp = admin.firestore.Timestamp;

/**
 * Deletes the given document references in batches of up to 500 writes
 * (Firestore's hard limit per batched write). Returns the number deleted.
 */
async function deleteInBatches(docRefs) {
  let deleted = 0;
  for (let i = 0; i < docRefs.length; i += 500) {
    const slice = docRefs.slice(i, i + 500);
    const batch = db.batch();
    for (const ref of slice) {
      batch.delete(ref);
    }
    await batch.commit();
    deleted += slice.length;
  }
  return deleted;
}

exports.autoDeleteExpiredOrders = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const now = Timestamp.now();
    const cancelledCutoff = Timestamp.fromMillis(
      now.toMillis() - CANCELLED_TTL_MS
    );

    const ordersRef = db.collection("orders");

    // Condition A: cancelled at least 30 minutes ago.
    //   status == "cancelado" AND cancelledAt <= now - 30 min
    const cancelledSnap = await ordersRef
      .where("status", "==", "cancelado")
      .where("cancelledAt", "<=", cancelledCutoff)
      .get();

    // Condition B: pre-courier order that has passed its expiry.
    //   status in [...] AND expiresAt <= now
    const expiredSnap = await ordersRef
      .where("status", "in", EXPIRY_ELIGIBLE_STATUSES)
      .where("expiresAt", "<=", now)
      .get();

    // Collect unique doc refs. Firestore range filters already exclude docs
    // missing the field, but we guard defensively so legacy orders without a
    // cancelledAt / expiresAt are skipped silently regardless.
    const toDelete = new Map();

    for (const doc of cancelledSnap.docs) {
      const ts = doc.get("cancelledAt");
      if (!(ts instanceof Timestamp)) continue; // legacy / missing — skip
      if (ts.toMillis() <= cancelledCutoff.toMillis()) {
        toDelete.set(doc.id, doc.ref);
      }
    }

    for (const doc of expiredSnap.docs) {
      const ts = doc.get("expiresAt");
      if (!(ts instanceof Timestamp)) continue; // legacy / missing — skip
      if (ts.toMillis() <= now.toMillis()) {
        toDelete.set(doc.id, doc.ref);
      }
    }

    const refs = Array.from(toDelete.values());
    const deleted = await deleteInBatches(refs);

    functions.logger.info(
      `autoDeleteExpiredOrders: deleted ${deleted} order(s) ` +
        `(${cancelledSnap.size} cancelled-match, ${expiredSnap.size} expired-match).`
    );

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────
// Round-robin courier assignment
//
// Model (decided with the team): we LAYER on the existing status vocabulary
// rather than introduce new statuses. An order being offered to couriers keeps
// status "confirmed"; the offer itself lives in three dedicated fields:
//
//   assignedCourierId  — the single courier currently being offered the order
//   assignmentExpiresAt — when that 30s offer lapses
//   rejectedCouriers   — couriers who already passed in the CURRENT cycle
//
// A courier ACCEPTS by setting status "accepted" + courierId (see the courier
// app's OrderService.acceptOrder). The offer rotates CONTINUOUSLY: when the
// cycle is exhausted it resets and starts over, so the order keeps being
// offered (looping through couriers, or re-offered to a lone courier) until
// someone accepts or it is cancelled. It only parks as "sin_repartidor" when
// there are zero online active couriers.
// ─────────────────────────────────────────────────────────────────────────

const OFFER_WINDOW_MS = 30 * 1000; // must match the courier app countdown
const FieldValue = admin.firestore.FieldValue;

/**
 * An order "needs a courier" when it is still confirmed, unclaimed, and has no
 * live offer outstanding. This is the single predicate that drives every
 * dispatch trigger below — an order is (re)offered exactly when it ENTERS this
 * state, which keeps the onCreate / onUpdate triggers from looping.
 */
function needsCourier(data) {
  return (
    !!data &&
    data.status === "confirmed" &&
    !data.courierId &&
    !data.assignedCourierId
  );
}

/**
 * Offers `orderRef` to the next eligible courier in a CONTINUOUS round-robin.
 * Wrapped in a transaction so two triggers firing for the same order can never
 * double-offer it.
 *
 * Courier eligibility (matches the existing field names):
 *   online == true          — courier is connected
 *   status == "active"      — courier is approved (couriers.status, not an
 *                             "approved" flag — that field does not exist)
 *
 * Round-robin determinism: candidates are sorted by document id, so the same
 * set of available couriers always yields the same order. As couriers
 * reject/timeout they accumulate in `rejectedCouriers` and are skipped, so
 * successive offers rotate through the list (courier1 → courier2 → courier3…).
 *
 * CONTINUOUS rotation (the key behaviour for the spec): when every online
 * courier has already passed in the current cycle (`rejectedCouriers` covers
 * them all) we do NOT give up — we RESET the cycle and start over from the top.
 * This means:
 *   • with several couriers, the offer loops 1 → 2 → 3 → 1 → … forever;
 *   • with a single active courier, the order is re-offered to that same
 *     courier every window indefinitely.
 * The loop only ever stops when a courier accepts (status → "accepted") or the
 * order is cancelled. The order is parked as "sin_repartidor" ONLY when there
 * are literally zero online active couriers; an admin "Reasignar" (or a courier
 * coming online and the order being reset) restarts the rotation.
 */
async function offerToNextCourier(orderRef) {
  // The candidate query is a non-transactional read (a collection query inside
  // a txn would force all reads before writes for no consistency gain — courier
  // online state is eventually consistent regardless).
  const couriersSnap = await db
    .collection("couriers")
    .where("online", "==", true)
    .where("status", "==", "active")
    .get();
  const onlineUids = couriersSnap.docs.map((d) => d.id).sort();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    if (!snap.exists) return;
    const order = snap.data();

    // Re-check under the transaction: the order may have been claimed,
    // cancelled, or already re-offered between trigger and execution.
    if (order.status !== "confirmed") return;
    if (order.courierId) return;
    if (order.assignedCourierId) return;

    // No couriers online at all — nothing to rotate through. Park the order so
    // the admin can retry; it cannot self-recover until a courier exists.
    if (onlineUids.length === 0) {
      tx.update(orderRef, {
        status: "sin_repartidor",
        assignedCourierId: null,
        assignmentExpiresAt: null,
      });
      functions.logger.info(
        `offerToNextCourier: ${orderRef.id} -> sin_repartidor (0 online).`
      );
      return;
    }

    let rejected = Array.isArray(order.rejectedCouriers)
      ? order.rejectedCouriers
      : [];
    let candidates = onlineUids.filter((uid) => !rejected.includes(uid));

    // Everyone in the current cycle has already passed → start a fresh cycle.
    // This is what makes the rotation continuous (and re-offers to a lone
    // courier indefinitely).
    if (candidates.length === 0) {
      rejected = [];
      candidates = onlineUids;
    }

    const next = candidates[0];
    tx.update(orderRef, {
      assignedCourierId: next,
      assignmentExpiresAt: Timestamp.fromMillis(Date.now() + OFFER_WINDOW_MS),
      // Persist the (possibly reset) cycle so the next rotation is correct.
      rejectedCouriers: rejected,
      // status stays "confirmed"
    });
    functions.logger.info(
      `offerToNextCourier: ${orderRef.id} offered to ${next} ` +
        `(${candidates.length} candidate(s), ${onlineUids.length} online).`
    );
  });
}

// Trigger A — a brand-new order created already in the "needs a courier" state.
exports.offerOrderOnCreate = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap) => {
    if (!needsCourier(snap.data())) return null;
    await offerToNextCourier(snap.ref);
    return null;
  });

// Trigger B — an order RE-ENTERS the "needs a courier" state: a courier
// released it (reject / client-side timeout writes assignedCourierId -> null),
// the scheduled backstop released it, or an admin reset it ("Reasignar").
// Firing only on the false→true edge of needsCourier prevents the offer write
// (which sets assignedCourierId) from re-triggering this handler.
exports.offerOrderOnReleased = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (needsCourier(after) && !needsCourier(before)) {
      await offerToNextCourier(change.after.ref);
    }
    return null;
  });

// Backstop — Firebase scheduled functions cannot run faster than 1 minute, so
// they cannot enforce the 30s window in real time. The courier app releases its
// own lapsed offer immediately (OrderService.releaseOffer); this sweep is the
// safety net that keeps the round-robin turning no matter what.
//
// It scans every "confirmed" (unclaimed) order and, CRUCIALLY, re-offers by
// calling offerToNextCourier DIRECTLY instead of relying on the onUpdate
// false→true edge of needsCourier — that edge can be missed (e.g. an order
// already sitting in needsCourier=true with no live offer because a previous
// offer attempt failed, or the courier app released without the trigger
// rotating). offerToNextCourier is transactional and idempotent, so calling it
// when an offer is already live is a no-op.
//
// Two cases per confirmed/unclaimed order:
//   • a live offer whose 30s window lapsed → record the courier as passed,
//     clear the offer, and immediately rotate to the next courier;
//   • no live offer at all (needsCourier, stranded) → (re)offer it.
exports.reclaimExpiredOffers = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const now = Timestamp.now();
    const snap = await db
      .collection("orders")
      .where("status", "==", "confirmed")
      .get();

    let reclaimed = 0; // lapsed offers rotated to the next courier
    let renudged = 0; // stranded orders re-offered from scratch
    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.courierId) continue; // already claimed — skip

      if (data.assignedCourierId) {
        // A courier is currently being offered this order. Only act once the
        // 30s window has lapsed; otherwise leave the live offer alone.
        const exp = data.assignmentExpiresAt;
        const lapsed =
          exp && typeof exp.toMillis === "function"
            ? exp.toMillis() <= now.toMillis()
            : false;
        if (!lapsed) continue;
        await doc.ref.update({
          rejectedCouriers: FieldValue.arrayUnion(data.assignedCourierId),
          assignedCourierId: null,
          assignmentExpiresAt: null,
        });
        // Rotate directly — do NOT depend on offerOrderOnReleased's edge.
        await offerToNextCourier(doc.ref);
        reclaimed += 1;
      } else {
        // Confirmed, unclaimed, and no live offer → it "needs a courier" but is
        // stranded. Re-offer it directly.
        await offerToNextCourier(doc.ref);
        renudged += 1;
      }
    }

    if (reclaimed > 0 || renudged > 0) {
      functions.logger.info(
        `reclaimExpiredOffers: rotated ${reclaimed} lapsed offer(s), ` +
          `re-offered ${renudged} stranded order(s).`
      );
    }
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────
// Manual reassignment (admin "Reasignar repartidor")
//
// The admin used to write the reset fields straight to Firestore and hope the
// onUpdate false→true edge of needsCourier re-fired the dispatcher. That edge
// is fragile: if the order was ALREADY in needsCourier=true (e.g. a prior
// timeout that never got reclaimed), the write doesn't cross the edge and no
// offer is made. This callable removes that dependency: it resets the rotation
// and then calls offerToNextCourier DIRECTLY, so a courier is always (re)offered
// from the start of the queue. Runs with the Admin SDK (bypasses rules), so we
// gate it on the caller being a signed-in admin (admins/{uid}).
// ─────────────────────────────────────────────────────────────────────────
exports.manualReassign = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Debes iniciar sesión."
    );
  }
  const adminDoc = await db.collection("admins").doc(context.auth.uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Solo administradores pueden reasignar."
    );
  }

  const orderId = data && data.orderId;
  if (!orderId || typeof orderId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Falta orderId."
    );
  }

  const orderRef = db.collection("orders").doc(orderId);
  const snap = await orderRef.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "Pedido no encontrado.");
  }

  // Restart the round-robin from the beginning of the queue: drop any claimed /
  // offered courier and the whole rejection history, back to "confirmed".
  await orderRef.update({
    courierId: null,
    courierName: null,
    status: "confirmed",
    assignedCourierId: null,
    assignmentExpiresAt: null,
    rejectedCouriers: [],
  });

  // Offer immediately and directly — independent of the onUpdate edge.
  await offerToNextCourier(orderRef);

  functions.logger.info(
    `manualReassign: ${orderId} reset and re-offered by ${context.auth.uid}.`
  );
  return { ok: true };
});
