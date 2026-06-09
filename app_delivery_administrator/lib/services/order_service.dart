import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  /// Restarts round-robin dispatch from the beginning of the queue. Invokes the
  /// `manualReassign` Cloud Function, which resets the rotation (clears the
  /// assigned courier + the whole rejection history, back to 'confirmed') AND
  /// immediately re-offers the order by calling the dispatcher directly.
  ///
  /// We call the function rather than writing to Firestore directly because the
  /// old direct write relied on the onUpdate false→true edge of `needsCourier`
  /// to re-trigger dispatch — and that edge is missed when the order is already
  /// in the "needs a courier" state (e.g. after an unreclaimed timeout), so no
  /// new offer was made. The callable removes that dependency. Used both to
  /// retry a 'sin_repartidor' order and to force a reassignment while searching.
  static Future<void> reassign(String id) async {
    await FirebaseFunctions.instance
        .httpsCallable('manualReassign')
        .call(<String, dynamic>{'orderId': id});
  }
}
