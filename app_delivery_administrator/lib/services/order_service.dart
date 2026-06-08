import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

class OrderService {
  static final _col = FirebaseFirestore.instance.collection('orders');

  /// Real-time stream of every order in the system, newest first.
  static Stream<List<OrderModel>> streamAll({int limit = 200}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .toList());
  }

  static Stream<List<OrderModel>> streamActive() {
    return _col
        .where('status',
            whereIn: ['pending', 'confirmed', 'preparing', 'accepted',
              'picked_up', 'en_camino', 'searching', 'sin_repartidor'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .toList());
  }

  static Future<OrderModel?> get(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return OrderModel.fromMap(snap.id, snap.data()!);
  }

  static Stream<OrderModel?> streamOne(String id) {
    return _col.doc(id).snapshots().map(
        (s) => s.exists ? OrderModel.fromMap(s.id, s.data()!) : null);
  }

  /// Cancel an order from the admin panel (audit trail field is added).
  static Future<void> cancel(String id, {String? reason}) {
    return _col.doc(id).update({
      'status': 'cancelado',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': 'admin',
      'cancelReason': ?reason,
    });
  }

  /// Permanently deletes an order document. Only used from the admin panel for
  /// cancelled orders; the scheduled Cloud Function also deletes via Admin SDK.
  static Future<void> delete(String id) {
    return _col.doc(id).delete();
  }

  /// Restarts round-robin dispatch from the beginning. Clears any assigned
  /// courier and the whole rejection history, and moves the order back to
  /// 'confirmed' so the Cloud Function's onUpdate trigger re-offers it to the
  /// first eligible courier. Used both to retry a 'sin_repartidor' order and to
  /// force a reassignment while still searching.
  static Future<void> reassign(String id) {
    return _col.doc(id).update({
      'courierId': null,
      'courierName': null,
      'status': 'confirmed',
      'assignedCourierId': null,
      'assignmentExpiresAt': null,
      'rejectedCouriers': <String>[],
    });
  }
}
