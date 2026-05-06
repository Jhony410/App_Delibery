import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String id;
  final String authorName;
  final String authorRole; // Cliente | Repartidor | Comercio
  final String subject;
  final String? orderId;
  final String status; // open | in_progress | waiting | resolved
  final String priority; // low | normal | high | urgent
  final DateTime createdAt;
  final DateTime? lastReplyAt;
  final bool unread;

  const TicketModel({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.subject,
    this.orderId,
    this.status = 'open',
    this.priority = 'normal',
    required this.createdAt,
    this.lastReplyAt,
    this.unread = false,
  });

  String get statusLabel => switch (status) {
        'open' => priority == 'urgent' ? 'Urgente' : 'Abierto',
        'in_progress' => 'En proceso',
        'waiting' => 'Esperando',
        'resolved' => 'Resuelto',
        _ => status,
      };

  String get statusTone => switch (status) {
        'open' => priority == 'urgent' ? 'red' : 'amber',
        'in_progress' => 'amber',
        'waiting' => 'blue',
        'resolved' => 'gray',
        _ => 'gray',
      };

  factory TicketModel.fromMap(String id, Map<String, dynamic> m) =>
      TicketModel(
        id: id,
        authorName: m['authorName'] ?? '',
        authorRole: m['authorRole'] ?? 'Cliente',
        subject: m['subject'] ?? '',
        orderId: m['orderId'],
        status: m['status'] ?? 'open',
        priority: m['priority'] ?? 'normal',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastReplyAt: (m['lastReplyAt'] as Timestamp?)?.toDate(),
        unread: m['unread'] ?? false,
      );
}
