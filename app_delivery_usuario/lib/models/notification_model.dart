import 'package:cloud_firestore/cloud_firestore.dart';

/// A single entry in `users/{uid}/notifications`. Written by other parts of the
/// platform (admin panel / Cloud Functions) via the Firestore-as-bus pattern;
/// the customer app only reads and marks them as read.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool read;
  final String? type;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.read = false,
    this.type,
    this.createdAt,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> m) =>
      NotificationModel(
        id: id,
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        read: m['read'] ?? false,
        type: m['type'] as String?,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}
