/// A single selectable option within a product option group
/// (`sizes`, `extras`, or `cutlery`). Stored as an embedded map
/// `{name, price}` — mirrors the customer app's `ProductVariant` /
/// `ProductExtra` shape so the customer product screen can read it as-is.
class ProductOption {
  final String name;
  final double price;

  const ProductOption({required this.name, this.price = 0});

  factory ProductOption.fromMap(Map<String, dynamic> m) => ProductOption(
        name: m['name'] ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {'name': name, 'price': price};

  ProductOption copyWith({String? name, double? price}) => ProductOption(
        name: name ?? this.name,
        price: price ?? this.price,
      );
}

/// A product/menu item stored under `stores/{storeId}/products/{productId}`.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;

  /// Required, single-select. The chosen size's price REPLACES [price]
  /// on the customer app. Empty = product has no size options.
  final List<ProductOption> sizes;

  /// Optional, multi-select. Each selected extra's price ADDS to the total.
  /// Price 0 renders as "Gratis" on the customer app.
  final List<ProductOption> extras;

  /// Optional, multi-select cutlery choices (same shape as [extras]).
  final List<ProductOption> cutlery;

  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.category = '',
    this.imageUrl = '',
    this.isAvailable = true,
    this.sizes = const [],
    this.extras = const [],
    this.cutlery = const [],
  });

  static List<ProductOption> _optionsFrom(dynamic raw) =>
      (raw as List? ?? [])
          .map((o) => ProductOption.fromMap(Map<String, dynamic>.from(o as Map)))
          .toList();

  factory ProductModel.fromMap(String id, Map<String, dynamic> m) =>
      ProductModel(
        id: id,
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        category: m['category'] ?? '',
        imageUrl: m['imageUrl'] ?? m['imagen_url'] ?? '',
        // Tolerate the alternate `available` key some catalog writers use.
        isAvailable: m['isAvailable'] ?? m['available'] ?? true,
        sizes: _optionsFrom(m['sizes']),
        extras: _optionsFrom(m['extras']),
        cutlery: _optionsFrom(m['cutlery']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
        'sizes': sizes.map((o) => o.toMap()).toList(),
        'extras': extras.map((o) => o.toMap()).toList(),
        'cutlery': cutlery.map((o) => o.toMap()).toList(),
      };

  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    List<ProductOption>? sizes,
    List<ProductOption>? extras,
    List<ProductOption>? cutlery,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        isAvailable: isAvailable ?? this.isAvailable,
        sizes: sizes ?? this.sizes,
        extras: extras ?? this.extras,
        cutlery: cutlery ?? this.cutlery,
      );
}
