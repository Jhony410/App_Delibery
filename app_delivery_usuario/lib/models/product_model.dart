class ProductVariant {
  final String name;
  final double price;

  const ProductVariant({required this.name, required this.price});

  factory ProductVariant.fromMap(Map<String, dynamic> m) =>
      ProductVariant(name: m['name'], price: (m['price'] as num).toDouble());

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

class ProductExtra {
  final String name;
  final double price;

  const ProductExtra({required this.name, required this.price});

  factory ProductExtra.fromMap(Map<String, dynamic> m) =>
      ProductExtra(name: m['name'], price: (m['price'] as num).toDouble());

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

class ProductModel {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final String tone;
  final String? badge;
  final String category;
  final List<ProductVariant> sizes;
  final List<ProductExtra> extras;
  final bool isAvailable;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.tone = 'warm',
    this.badge,
    this.sizes = const [],
    this.extras = const [],
    this.isAvailable = true,
  });

  factory ProductModel.fromMap(String id, String storeId, Map<String, dynamic> m) =>
      ProductModel(
        id: id,
        storeId: storeId,
        name: m['name'],
        description: m['description'] ?? '',
        price: (m['price'] as num).toDouble(),
        tone: m['tone'] ?? 'warm',
        badge: m['badge'],
        category: m['category'] ?? 'Destacados',
        isAvailable: m['isAvailable'] ?? true,
        sizes: (m['sizes'] as List? ?? [])
            .map((s) => ProductVariant.fromMap(Map<String, dynamic>.from(s)))
            .toList(),
        extras: (m['extras'] as List? ?? [])
            .map((e) => ProductExtra.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'tone': tone,
        'badge': badge,
        'category': category,
        'isAvailable': isAvailable,
        'sizes': sizes.map((s) => s.toMap()).toList(),
        'extras': extras.map((e) => e.toMap()).toList(),
      };
}
