import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/store_model.dart';

class StoreService {
  static final _col = FirebaseFirestore.instance.collection('stores');

  static Stream<List<StoreModel>> streamAll() {
    return _col.orderBy('name').snapshots().map((s) => s.docs
        .map((d) => StoreModel.fromMap(d.id, d.data()))
        .toList());
  }

  static Future<StoreModel?> get(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return StoreModel.fromMap(snap.id, snap.data()!);
  }

  static Future<void> updateOpen(String id, bool isOpen) =>
      _col.doc(id).update({'isOpen': isOpen});

  static Future<void> updateCommission(String id, double pct) =>
      _col.doc(id).update({'commissionPct': pct});
}
