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

  /// Toggle the courier online/offline while tracking session time.
  ///
  /// Going online stamps `onlineSince`. Going offline reads it, adds the elapsed
  /// seconds to today's `onlineByDay` bucket and clears the stamp. Runs in a
  /// transaction so the accumulation can't race with a concurrent read. All
  /// fields live on `couriers/{uid}`, which the courier already owns — no rules
  /// change needed.
  static Future<void> setOnline(String uid, bool online) async {
    final ref = _db.collection('couriers').doc(uid);
    if (online) {
      await ref.update({
        'online': true,
        'onlineSince': FieldValue.serverTimestamp(),
      });
      return;
    }
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      final updates = <String, dynamic>{
        'online': false,
        'onlineSince': null,
      };
      final since = (data?['onlineSince'] as Timestamp?)?.toDate();
      if (since != null) {
        final elapsed = DateTime.now().difference(since).inSeconds;
        if (elapsed > 0) {
          final key = CourierModel.dayKey(DateTime.now());
          updates['onlineByDay.$key'] = FieldValue.increment(elapsed);
        }
      }
      tx.update(ref, updates);
    });
  }

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

  /// Full recent notification feed for the bell on the home screen.
  static Stream<List<CourierNotice>> streamNotices(String uid) => _db
      .collection('couriers')
      .doc(uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs
          .map((d) => CourierNotice.fromMap(d.id, d.data()))
          .toList());

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
