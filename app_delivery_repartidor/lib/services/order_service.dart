import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  static final _db = FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────────────────
  // Dispatch is Firestore-only (no FCM, by design — see the team decision).
  //
  // Broadcast model: every unclaimed, ready order is offered to ALL online
  // couriers simultaneously through `streamAvailable()`. The first courier to
  // accept wins via the atomic `acceptOrder` transaction; the rest see the
  // order disappear from their stream. This works only while the app is
  // foregrounded and online (Firestore-as-bus).
  //
  // FUTURE WORK: to wake a backgrounded/closed courier, add `firebase_messaging`
  // and push from the backend (tokens must never be sent from a client).
  // ───────────────────────────────────────────────────────────────────────

  /// Orders available to be claimed: ready for a courier (`confirmed` or
  /// `preparing`) and not yet taken (`courierId == null`). Broadcast to every
  /// online courier — this is the trigger for the new-order popup; see
  /// HomeScreen.
  static Stream<List<OrderModel>> streamAvailable() => _db
      .collection('orders')
      .where('status', whereIn: ['confirmed', 'preparing'])
      .where('courierId', isNull: true)
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
      });
      return true;
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
