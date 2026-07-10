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
  final List<ProductExtra> cutlery;
  final bool isAvailable;

  /// Imagen real del producto (subida desde el panel admin a Firebase Storage
  /// o pegada como URL externa). Null/vacío = usar el asset local.
  final String? imageUrl;

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
    this.cutlery = const [],
    this.isAvailable = true,
    this.imageUrl,
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
        imageUrl: m['imageUrl'] ?? m['imagen_url'],
        sizes: (m['sizes'] as List? ?? [])
            .map((s) => ProductVariant.fromMap(Map<String, dynamic>.from(s)))
            .toList(),
        extras: (m['extras'] as List? ?? [])
            .map((e) => ProductExtra.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        cutlery: (m['cutlery'] as List? ?? [])
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
        if (imageUrl != null) 'imageUrl': imageUrl,
        'sizes': sizes.map((s) => s.toMap()).toList(),
        'extras': extras.map((e) => e.toMap()).toList(),
        'cutlery': cutlery.map((e) => e.toMap()).toList(),
      };
}
