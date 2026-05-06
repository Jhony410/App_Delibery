import 'package:flutter/material.dart';

class ZoneModel {
  final String id;
  final String name;
  final String description;
  final Color color;
  final bool active;
  final bool draft;
  final double? multiplier;
  final double? minFee;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.active = true,
    this.draft = false,
    this.multiplier,
    this.minFee,
  });

  String get statusLabel => draft ? 'Borrador' : 'Operativa';
  String get statusTone => draft ? 'amber' : 'green';

  factory ZoneModel.fromMap(String id, Map<String, dynamic> m) => ZoneModel(
        id: id,
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        color: Color(int.tryParse(m['color']?.toString() ?? '0xFFFF6B35') ??
            0xFFFF6B35),
        active: m['active'] ?? true,
        draft: m['draft'] ?? false,
        multiplier: (m['multiplier'] as num?)?.toDouble(),
        minFee: (m['minFee'] as num?)?.toDouble(),
      );
}
