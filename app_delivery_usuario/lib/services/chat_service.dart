import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message_model.dart';

/// Real-time chat for an active order, backed entirely by Firestore.
/// Collection layout: /chats/{orderId}/messages/{messageId}.
class ChatService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _messages(String orderId) =>
      _db.collection('chats').doc(orderId).collection('messages');

  /// Live stream of all messages for an order, oldest first.
  static Stream<List<ChatMessage>> streamMessages(String orderId) => _messages(
        orderId,
      )
          .orderBy('timestamp')
          .snapshots()
          .map((s) => s.docs
              .map((d) => ChatMessage.fromMap(d.id, d.data()))
              .toList());

  static Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String senderRole, // 'user' | 'courier'
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _messages(orderId).add({
      'senderId': senderId,
      'senderRole': senderRole,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Marks every unread message from the *other* party as read.
  static Future<void> markReadFromOthers(String orderId, String myRole) async {
    final snap = await _messages(orderId).where('read', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      if (doc.data()['senderRole'] != myRole) {
        batch.update(doc.reference, {'read': true});
      }
    }
    await batch.commit();
  }
}
