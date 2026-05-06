class StoreModel {
  final String id;
  final String name;
  final String category;
  final String categorySlug;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final double deliveryFee;
  final bool isOpen;
  final String address;
  final String? promo;
  final String tone;
  final String? district;
  final String? phone;
  final double? commissionPct;
  final double? monthSales;

  const StoreModel({
    required this.id,
    required this.name,
    required this.category,
    required this.categorySlug,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.address,
    this.isOpen = true,
    this.promo,
    this.tone = 'warm',
    this.district,
    this.phone,
    this.commissionPct,
    this.monthSales,
  });

  factory StoreModel.fromMap(String id, Map<String, dynamic> m) => StoreModel(
        id: id,
        name: m['name'] ?? '',
        category: m['category'] ?? '',
        categorySlug: m['categorySlug'] ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: m['reviewCount'] ?? 0,
        deliveryTime: m['deliveryTime'] ?? '20-30 min',
        deliveryFee: (m['deliveryFee'] as num?)?.toDouble() ?? 0,
        isOpen: m['isOpen'] ?? true,
        address: m['address'] ?? '',
        promo: m['promo'],
        tone: m['tone'] ?? 'warm',
        district: m['district'],
        phone: m['phone'],
        commissionPct: (m['commissionPct'] as num?)?.toDouble(),
        monthSales: (m['monthSales'] as num?)?.toDouble(),
      );
}
