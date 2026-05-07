import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  static final _db = FirebaseFirestore.instance;

  /// Orders awaiting a courier — store has finished preparing.
  /// Filters `courierId == null` client-side so it matches both explicit-null
  /// and legacy docs that omit the field entirely (Firestore `isNull: true`
  /// only matches the explicit case).
  static Stream<List<OrderModel>> streamAvailable() => _db
      .collection('orders')
      .where('status', whereIn: ['confirmed', 'preparing'])
      .snapshots()
      .map((s) => s.docs
          .map((d) => OrderModel.fromMap(d.id, d.data()))
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

  /// Atomically claim an order for a courier (only if unassigned).
  static Future<bool> acceptOrder(String orderId, String courierId) async {
    final ref = _db.collection('orders').doc(orderId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      if (data['courierId'] != null) return false;
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

  static Future<void> rejectOrder(String orderId) =>
      _db.collection('orders').doc(orderId).update({
        'rejectedCount': FieldValue.increment(1),
      });
}
