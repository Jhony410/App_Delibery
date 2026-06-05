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

  /// Most recent in-app notification the admin wrote (approval / rejection).
  /// Streamed in real time so the review screen reacts the instant the admin
  /// acts — the Firebase-only stand-in for an FCM push.
  static Stream<CourierNotice?> streamLatestNotice(String uid) => _db
      .collection('couriers')
      .doc(uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty
          ? null
          : CourierNotice.fromMap(s.docs.first.id, s.docs.first.data()));

  static Future<void> markNoticeRead(String uid, String noticeId) => _db
      .collection('couriers')
      .doc(uid)
      .collection('notifications')
      .doc(noticeId)
      .update({'read': true});
}

/// A lightweight in-app notification delivered through Firestore.
class CourierNotice {
  final String id;
  final String type; // approval | rejection
  final String title;
  final String body;
  final bool read;

  const CourierNotice({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
  });

  factory CourierNotice.fromMap(String id, Map<String, dynamic> m) =>
      CourierNotice(
        id: id,
        type: m['type'] ?? '',
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        read: m['read'] ?? false,
      );
}
