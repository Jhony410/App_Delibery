import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  static final _db = FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────────────────
  // Dispatch is Firestore-only (no FCM, by design — see the team decision).
  //
  // Targeted round-robin model: the Cloud Functions dispatcher offers an order
  // to ONE courier at a time by writing `assignedCourierId` + a 30s
  // `assignmentExpiresAt`. Each courier only sees the offers addressed to them
  // through `streamOffersFor()`. The courier accepts (atomic `acceptOrder`) or
  // releases it (`releaseOffer`, on reject/timeout) — releasing re-fires the
  // dispatcher, which rotates to the next courier (or re-offers to the same
  // lone courier). This works only while the app is foregrounded and online
  // (Firestore-as-bus).
  //
  // FUTURE WORK: to wake a backgrounded/closed courier, add `firebase_messaging`
  // and push from the backend (tokens must never be sent from a client). The
  // scheduled `reclaimExpiredOffers` backstop already rotates offers stranded
  // by a closed app.
  // ───────────────────────────────────────────────────────────────────────

  /// Orders currently being offered to THIS courier by the round-robin
  /// dispatcher: still `confirmed` (unclaimed) and `assignedCourierId == uid`.
  /// This is the trigger for the new-order popup; see HomeScreen. Backed by the
  /// `assignedCourierId + status` composite index.
  static Stream<List<OrderModel>> streamOffersFor(String courierId) => _db
      .collection('orders')
      .where('assignedCourierId', isEqualTo: courierId)
      .where('status', isEqualTo: 'confirmed')
      .snapshots()
      .map((s) => s.docs
          .map((d) => OrderModel.fromMap(d.id, d.data()))
          // Defensive: never surface an order another courier already claimed.
          .where((o) => o.courierId == null)
          .toList());

  /// All orders the courier has been assigned to.
  static Stream<List<OrderModel>> streamForCourier(String courierId) => _db
      .collection('orders')
      .where('courierId', isEqualTo: courierId)
      .snapshots()
      .map((s) {
        final list = s.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  /// Active deliveries (not finished).
  static Stream<List<OrderModel>> streamActiveForCourier(String courierId) => _db
      .collection('orders')
      .where('courierId', isEqualTo: courierId)
      .where('status', whereIn: ['accepted', 'picked_up', 'en_camino'])
      .snapshots()
      .map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());

  static Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.id, doc.data()!);
  }

  static Stream<OrderModel?> streamOrder(String orderId) =>
      _db.collection('orders').doc(orderId).snapshots().map(
            (d) => d.exists ? OrderModel.fromMap(d.id, d.data()!) : null,
          );

  /// Atomically claim an available order for this courier. Wins only if the
  /// order is still unclaimed (`courierId == null`) and ready (`confirmed` or
  /// `preparing`) — the first courier to commit the transaction takes it; any
  /// later attempt returns false. Locks the order by setting `courierId` +
  /// status 'accepted'.
  static Future<bool> acceptOrder(String orderId, String courierId) async {
    final ref = _db.collection('orders').doc(orderId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      if (data['courierId'] != null) return false;
      final status = data['status'];
      if (status != 'confirmed' && status != 'preparing') return false;
      tx.update(ref, {
        'courierId': courierId,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        // Clear the round-robin offer so the dispatcher stops rotating it and
        // the admin/user panels resolve the driver from courierId.
        'assignedCourierId': null,
        'assignmentExpiresAt': null,
      });
      return true;
    });
  }

  /// Release an offer this courier rejected or let time out, handing the order
  /// back to the round-robin dispatcher. Records the courier in
  /// `rejectedCouriers` (so the current cycle skips them) and clears the offer;
  /// clearing `assignedCourierId` re-fires the Cloud Functions `offerOrderOn
  /// Released` trigger, which immediately rotates to the next courier — or, when
  /// this is the only active courier, re-offers to them with a fresh 30s window.
  /// Guarded so it only touches an offer still addressed to this courier.
  static Future<void> releaseOffer(String orderId, String courierId) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      // Only release if the offer is still ours and unclaimed.
      if (data['courierId'] != null) return;
      if (data['assignedCourierId'] != courierId) return;
      tx.update(ref, {
        'rejectedCouriers': FieldValue.arrayUnion([courierId]),
        'assignedCourierId': null,
        'assignmentExpiresAt': null,
      });
    });
  }

  static Future<void> markPickedUp(String orderId) =>
      _db.collection('orders').doc(orderId).update({
        'status': 'picked_up',
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

  static Future<void> markEnRoute(String orderId) =>
      _db.collection('orders').doc(orderId).update({
        'status': 'en_camino',
      });

  static Future<void> markDelivered(String orderId) =>
      _db.collection('orders').doc(orderId).update({
        'status': 'entregado',
        'deliveredAt': FieldValue.serverTimestamp(),
      });
}
