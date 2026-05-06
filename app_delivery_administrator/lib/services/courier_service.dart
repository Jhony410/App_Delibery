import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/courier_model.dart';

class CourierService {
  static final _col = FirebaseFirestore.instance.collection('couriers');

  static Stream<List<CourierModel>> streamAll() {
    return _col.orderBy('name').snapshots().map((s) => s.docs
        .map((d) => CourierModel.fromMap(d.id, d.data()))
        .toList());
  }

  static Stream<List<CourierModel>> streamPendingApproval() {
    return _col
        .where('status', isEqualTo: 'pending_review')
        .snapshots()
        .map((s) => s.docs
            .map((d) => CourierModel.fromMap(d.id, d.data()))
            .toList());
  }

  static Future<CourierModel?> get(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    return CourierModel.fromMap(snap.id, snap.data()!);
  }

  static Future<void> approve(String uid) =>
      _col.doc(uid).update({'status': 'active'});

  static Future<void> reject(String uid) =>
      _col.doc(uid).update({'status': 'rejected'});

  static Future<void> suspend(String uid) =>
      _col.doc(uid).update({'status': 'suspended'});
}
