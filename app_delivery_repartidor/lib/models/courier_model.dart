import 'package:cloud_firestore/cloud_firestore.dart';

class CourierModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String dni;
  final String vehiclePlate;
  final String vehicleModel;
  final String bankAccount;
  final DateTime memberSince;
  final int totalDeliveries;
  final double totalEarnings;
  final double rating;
  final double acceptanceRate;
  final String status; // pending_review | active | suspended
  final bool online;

  const CourierModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.dni = '',
    this.vehiclePlate = '',
    this.vehicleModel = '',
    this.bankAccount = '',
    required this.memberSince,
    this.totalDeliveries = 0,
    this.totalEarnings = 0,
    this.rating = 5.0,
    this.acceptanceRate = 1.0,
    this.status = 'pending_review',
    this.online = false,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'R';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get isVerified => status == 'active';

  factory CourierModel.fromMap(String uid, Map<String, dynamic> m) =>
      CourierModel(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        dni: m['dni'] ?? '',
        vehiclePlate: m['vehiclePlate'] ?? '',
        vehicleModel: m['vehicleModel'] ?? '',
        bankAccount: m['bankAccount'] ?? '',
        memberSince: (m['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
        totalDeliveries: m['totalDeliveries'] ?? 0,
        totalEarnings: (m['totalEarnings'] as num?)?.toDouble() ?? 0,
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        acceptanceRate: (m['acceptanceRate'] as num?)?.toDouble() ?? 1.0,
        status: m['status'] ?? 'pending_review',
        online: m['online'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'dni': dni,
        'vehiclePlate': vehiclePlate,
        'vehicleModel': vehicleModel,
        'bankAccount': bankAccount,
        'memberSince': Timestamp.fromDate(memberSince),
        'totalDeliveries': totalDeliveries,
        'totalEarnings': totalEarnings,
        'rating': rating,
        'acceptanceRate': acceptanceRate,
        'status': status,
        'online': online,
        'role': 'courier',
      };

  CourierModel copyWith({
    String? name,
    String? phone,
    String? dni,
    String? vehiclePlate,
    String? vehicleModel,
    String? bankAccount,
    String? status,
    bool? online,
  }) =>
      CourierModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        dni: dni ?? this.dni,
        vehiclePlate: vehiclePlate ?? this.vehiclePlate,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        bankAccount: bankAccount ?? this.bankAccount,
        memberSince: memberSince,
        totalDeliveries: totalDeliveries,
        totalEarnings: totalEarnings,
        rating: rating,
        acceptanceRate: acceptanceRate,
        status: status ?? this.status,
        online: online ?? this.online,
      );
}
