import 'package:cloud_firestore/cloud_firestore.dart';

/// One message in an order chat: /chats/{orderId}/messages/{messageId}.
/// Shared shape with the courier app (duplicated locally on purpose — the two
/// apps are independent packages that only share the Firestore database).
class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole; // user | courier
  final String text;
  final DateTime? timestamp;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) => ChatMessage(
        id: id,
        senderId: m['senderId'] ?? '',
        senderRole: m['senderRole'] ?? '',
        text: m['text'] ?? '',
        // serverTimestamp is briefly null on the sender's own optimistic write.
        timestamp: (m['timestamp'] as Timestamp?)?.toDate(),
        read: m['read'] ?? false,
      );

  bool get isUser => senderRole == 'user';
}
