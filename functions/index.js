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
 *                           offers whose 15s window lapsed without the offered
 *                           courier's app responding (e.g. app was closed).
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
//   assignmentExpiresAt — when that 15s offer lapses
//   rejectedCouriers   — couriers who already rejected / timed out
//
// A courier ACCEPTS by setting status "accepted" + courierId (see the courier
// app's OrderService.acceptOrder). When no courier is left the order moves to
// the terminal-ish status "sin_repartidor" for the admin to retry manually.
// ─────────────────────────────────────────────────────────────────────────

const OFFER_WINDOW_MS = 15 * 1000; // must match the courier app countdown
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
 * Offers `orderRef` to the next eligible courier, or marks it
 * "sin_repartidor" when none remain. Wrapped in a transaction so two triggers
 * firing for the same order can never double-offer it.
 *
 * Courier eligibility (matches the existing field names):
 *   online == true          — courier is connected
 *   status == "active"      — courier is approved (couriers.status, not an
 *                             "approved" flag — that field does not exist)
 *   uid NOT in rejectedCouriers
 *
 * Round-robin determinism (constraint #5): candidates are sorted by document
 * id, so the same set of available couriers always yields the same order. As
 * couriers reject/timeout they accumulate in rejectedCouriers and are skipped,
 * so successive offers rotate through the list.
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

    const rejected = Array.isArray(order.rejectedCouriers)
      ? order.rejectedCouriers
      : [];
    const candidates = onlineUids.filter((uid) => !rejected.includes(uid));

    if (candidates.length === 0) {
      tx.update(orderRef, {
        status: "sin_repartidor",
        assignedCourierId: null,
        assignmentExpiresAt: null,
      });
      functions.logger.info(
        `offerToNextCourier: ${orderRef.id} -> sin_repartidor ` +
          `(${onlineUids.length} online, all rejected).`
      );
      return;
    }

    const next = candidates[0];
    tx.update(orderRef, {
      assignedCourierId: next,
      assignmentExpiresAt: Timestamp.fromMillis(Date.now() + OFFER_WINDOW_MS),
      // status stays "confirmed"
    });
    functions.logger.info(
      `offerToNextCourier: ${orderRef.id} offered to ${next}.`
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
// they cannot enforce the 15s window in real time. The courier app releases its
// own lapsed offer immediately; this sweep only catches offers stranded because
// the offered courier's app was backgrounded / closed and never wrote back.
// Releasing the offer here (assignedCourierId -> null) re-fires Trigger B.
exports.reclaimExpiredOffers = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const now = Timestamp.now();
    const snap = await db
      .collection("orders")
      .where("status", "==", "confirmed")
      .where("assignmentExpiresAt", "<=", now)
      .get();

    let reclaimed = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      if (!data.assignedCourierId) continue; // already released — skip
      await doc.ref.update({
        rejectedCouriers: FieldValue.arrayUnion(data.assignedCourierId),
        assignedCourierId: null,
        assignmentExpiresAt: null,
      });
      reclaimed += 1;
    }

    if (reclaimed > 0) {
      functions.logger.info(
        `reclaimExpiredOffers: released ${reclaimed} stranded offer(s).`
      );
    }
    return null;
  });
