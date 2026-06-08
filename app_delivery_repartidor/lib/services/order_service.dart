import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  static final _db = FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────────────────
  // Dispatch is Firestore-only (no FCM, by design — see the team decision).
  //
  // The round-robin dispatcher lives in Cloud Functions (functions/index.js):
  // it offers an order to ONE courier at a time by setting
  // `orders/{id}.assignedCourierId` + `assignmentExpiresAt`, keeping
  // status == 'confirmed' during the 15s window. The courier app reacts purely
  // through `streamMyOffers()` (Firestore-as-bus), which only works while the
  // app is foregrounded and online — the same limitation as before.
  //
  // FUTURE WORK: to wake a backgrounded/closed courier, add `firebase_messaging`
  // and have the dispatcher also push to the offered courier's saved token
  // (tokens must never be sent from a client; the send stays in the backend).
  // ───────────────────────────────────────────────────────────────────────

  /// Orders currently being OFFERED to this courier by the round-robin
  /// dispatcher (Cloud Functions). The dispatcher sets `assignedCourierId` to a
  /// single courier at a time and keeps `status == 'confirmed'` during the 15s
  /// offer window. This — not a broadcast — is the authoritative trigger for the
  /// new-order popup; see HomeScreen.
  static Stream<List<OrderModel>> streamMyOffers(String courierId) => _db
      .collection('orders')
      .where('assignedCourierId', isEqualTo: courierId)
      .where('status', isEqualTo: 'confirmed')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());

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

  /// Atomically accept the offer currently held by this courier. Succeeds only
  /// if the order is still unclaimed AND this courier is the one being offered it
  /// (the offer may have rotated away if they were slow). Clears the offer timer
  /// and locks the order to them by setting `courierId` + status 'accepted'.
  static Future<bool> acceptOrder(String orderId, String courierId) async {
    final ref = _db.collection('orders').doc(orderId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      if (data['courierId'] != null) return false;
      if (data['status'] != 'confirmed') return false;
      if (data['assignedCourierId'] != courierId) return false;
      tx.update(ref, {
        'courierId': courierId,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        // Clear the offer window — the order is now locked to this courier.
        'assignmentExpiresAt': null,
      });
      return true;
    });
  }

  /// Release the offer this courier was given — on explicit reject OR when the
  /// 15s countdown lapses. Records the rejection so the dispatcher never re-offers
  /// the order to this courier, and clears the offer so the Cloud Function's
  /// onUpdate trigger immediately offers it to the next courier. Status stays
  /// 'confirmed'.
  static Future<void> releaseOffer(String orderId, String courierId) =>
      _db.collection('orders').doc(orderId).update({
        'rejectedCouriers': FieldValue.arrayUnion([courierId]),
        'assignedCourierId': null,
        'assignmentExpiresAt': null,
      });

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
