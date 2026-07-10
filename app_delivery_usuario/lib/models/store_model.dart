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

  /// Foto real del local subida desde el panel admin (Firebase Storage).
  /// Null/vacío cuando el comercio aún no tiene foto — se usa el asset local.
  final String? imagenUrl;

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
    this.imagenUrl,
  });

  factory StoreModel.fromMap(String id, Map<String, dynamic> m) => StoreModel(
        id: id,
        name: m['name'],
        category: m['category'],
        categorySlug: m['categorySlug'] ?? '',
        rating: (m['rating'] as num).toDouble(),
        reviewCount: m['reviewCount'] ?? 0,
        deliveryTime: m['deliveryTime'],
        deliveryFee: (m['deliveryFee'] as num).toDouble(),
        isOpen: m['isOpen'] ?? true,
        address: m['address'],
        promo: m['promo'],
        tone: m['tone'] ?? 'warm',
        imagenUrl: m['imagenUrl'] ?? m['imagen_url'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'categorySlug': categorySlug,
        'rating': rating,
        'reviewCount': reviewCount,
        'deliveryTime': deliveryTime,
        'deliveryFee': deliveryFee,
        'isOpen': isOpen,
        'address': address,
        'promo': promo,
        'tone': tone,
        if (imagenUrl != null) 'imagenUrl': imagenUrl,
      };
}
