import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_model.dart';

class CustomerService {
  static final _col = FirebaseFirestore.instance.collection('users');

  static Stream<List<CustomerModel>> streamAll({int limit = 200}) {
    return _col.orderBy('name').limit(limit).snapshots().map((s) => s.docs
        .map((d) => CustomerModel.fromMap(d.id, d.data()))
        .toList());
  }

  static Future<CustomerModel?> get(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    return CustomerModel.fromMap(snap.id, snap.data()!);
  }
}
