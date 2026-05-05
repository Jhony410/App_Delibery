import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final DateTime memberSince;
  final int totalOrders;
  final double totalSpent;
  final double rating;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSince,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.rating = 5.0,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> m) => UserModel(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        memberSince: (m['memberSince'] as Timestamp).toDate(),
        totalOrders: m['totalOrders'] ?? 0,
        totalSpent: (m['totalSpent'] as num?)?.toDouble() ?? 0,
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'memberSince': Timestamp.fromDate(memberSince),
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'rating': rating,
      };
}
