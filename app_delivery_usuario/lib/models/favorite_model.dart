import 'package:cloud_firestore/cloud_firestore.dart';

/// A favourited store, stored at `users/{uid}/favorites/{storeId}`.
/// The document id is the storeId so favourites are idempotent (one per store).
class FavoriteModel {
  final String storeId;
  final String storeName;
  final DateTime? createdAt;

  const FavoriteModel({
    required this.storeId,
    required this.storeName,
    this.createdAt,
  });

  factory FavoriteModel.fromMap(String id, Map<String, dynamic> m) =>
      FavoriteModel(
        storeId: m['storeId'] ?? id,
        storeName: m['storeName'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'storeName': storeName,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
