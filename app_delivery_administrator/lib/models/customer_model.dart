import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final DateTime memberSince;
  final int totalOrders;
  final double totalSpent;
  final double rating;
  final String? district;
  final String segment; // VIP | Activo | Nuevo

  const CustomerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSince,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.rating = 5.0,
    this.district,
    this.segment = 'Nuevo',
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Tone for the segment Badge.
  String get segmentTone => switch (segment) {
        'VIP' => 'purple',
        'Nuevo' => 'blue',
        _ => 'green',
      };

  factory CustomerModel.fromMap(String uid, Map<String, dynamic> m) {
    final orders = m['totalOrders'] ?? 0;
    final spent = (m['totalSpent'] as num?)?.toDouble() ?? 0;
    String segment = 'Nuevo';
    if (orders >= 30 || spent >= 1500) {
      segment = 'VIP';
    } else if (orders >= 5) {
      segment = 'Activo';
    }
    return CustomerModel(
      uid: uid,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      phone: m['phone'] ?? '',
      memberSince:
          (m['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalOrders: orders,
      totalSpent: spent,
      rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
      district: m['district'],
      segment: m['segment'] ?? segment,
    );
  }
}
