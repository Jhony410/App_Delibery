import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/courier_model.dart';

class CourierService {
  static final _db = FirebaseFirestore.instance;
  static final _col = _db.collection('couriers');

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

  static Future<void> approve(String uid) async {
    await _col.doc(uid).update({
      'status': 'active',
      'approvedAt': FieldValue.serverTimestamp(),
    });
    await _notify(
      uid,
      type: 'approval',
      title: '¡Cuenta aprobada!',
      body:
          'Tu cuenta fue verificada. Ya puedes conectarte y empezar a recibir pedidos.',
    );
  }

  static Future<void> reject(String uid) async {
    await _col.doc(uid).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
    await _notify(
      uid,
      type: 'rejection',
      title: 'Solicitud rechazada',
      body:
          'Tu solicitud no fue aprobada. Escríbenos a soporte para revisar tu caso.',
    );
  }

  static Future<void> suspend(String uid) =>
      _col.doc(uid).update({'status': 'suspended'});

  /// Writes an in-app notification document that the courier app streams in
  /// real time (couriers/{uid}/notifications/{id}). This is the Firebase-only
  /// substitute for an FCM push: no server needed, delivered the instant the
  /// courier app has a live snapshot listener open.
  static Future<void> _notify(
    String uid, {
    required String type,
    required String title,
    required String body,
  }) =>
      _col.doc(uid).collection('notifications').add({
        'type': type,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
