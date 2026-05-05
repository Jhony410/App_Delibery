import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/courier_model.dart';

class CourierService {
  static final _db = FirebaseFirestore.instance;

  static Future<CourierModel?> getCourier(String uid) async {
    final doc = await _db.collection('couriers').doc(uid).get();
    if (!doc.exists) return null;
    return CourierModel.fromMap(uid, doc.data()!);
  }

  static Stream<CourierModel?> streamCourier(String uid) =>
      _db.collection('couriers').doc(uid).snapshots().map(
            (d) => d.exists ? CourierModel.fromMap(uid, d.data()!) : null,
          );

  static Future<void> updateCourier(String uid, Map<String, dynamic> data) =>
      _db.collection('couriers').doc(uid).update(data);

  static Future<void> setOnline(String uid, bool online) =>
      _db.collection('couriers').doc(uid).update({'online': online});

  static Future<void> incrementDelivery(String uid, double earning) =>
      _db.collection('couriers').doc(uid).update({
        'totalDeliveries': FieldValue.increment(1),
        'totalEarnings': FieldValue.increment(earning),
      });
}
