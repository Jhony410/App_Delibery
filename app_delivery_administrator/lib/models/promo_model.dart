import 'package:cloud_firestore/cloud_firestore.dart';

class PromoModel {
  final String id;
  final String code;
  final String description;
  final String benefit; // "50% hasta S/ 15", "100% en envío", etc.
  final String status; // active | scheduled | expired | draft
  final int uses;
  final int? cap;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const PromoModel({
    required this.id,
    required this.code,
    required this.description,
    required this.benefit,
    this.status = 'active',
    this.uses = 0,
    this.cap,
    this.startsAt,
    this.endsAt,
  });

  String get statusLabel => switch (status) {
        'active' => 'Activa',
        'scheduled' => 'Programada',
        'expired' => 'Vencida',
        'draft' => 'Borrador',
        _ => status,
      };

  String get statusTone => switch (status) {
        'active' => 'green',
        'scheduled' => 'blue',
        'expired' => 'gray',
        'draft' => 'amber',
        _ => 'gray',
      };

  String get usagePct {
    if (cap == null || cap == 0) return '—';
    return '${(uses / cap! * 100).toStringAsFixed(1)}%';
  }

  factory PromoModel.fromMap(String id, Map<String, dynamic> m) => PromoModel(
        id: id,
        code: m['code'] ?? id,
        description: m['description'] ?? '',
        benefit: m['benefit'] ?? '',
        status: m['status'] ?? 'active',
        uses: m['uses'] ?? 0,
        cap: m['cap'] as int?,
        startsAt: (m['startsAt'] as Timestamp?)?.toDate(),
        endsAt: (m['endsAt'] as Timestamp?)?.toDate(),
      );
}
