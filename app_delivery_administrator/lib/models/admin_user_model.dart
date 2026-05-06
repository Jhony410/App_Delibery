import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // super_admin | operations | finance | support | merchants | couriers | readonly
  final DateTime memberSince;
  final DateTime? lastActive;

  const AdminUserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.memberSince,
    this.lastActive,
  });

  String get roleLabel => switch (role) {
        'super_admin' => 'Super Admin',
        'operations' => 'Operaciones',
        'finance' => 'Finanzas',
        'support' => 'Soporte',
        'merchants' => 'Comercios',
        'couriers' => 'Repartidores',
        'readonly' => 'Solo lectura',
        _ => role,
      };

  String get roleTone => switch (role) {
        'super_admin' => 'purple',
        'operations' => 'blue',
        'finance' => 'green',
        'support' => 'amber',
        'merchants' => 'coral',
        'couriers' => 'blue',
        _ => 'gray',
      };

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory AdminUserModel.fromMap(String uid, Map<String, dynamic> m) =>
      AdminUserModel(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        role: m['role'] ?? 'readonly',
        memberSince:
            (m['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastActive: (m['lastActive'] as Timestamp?)?.toDate(),
      );
}
