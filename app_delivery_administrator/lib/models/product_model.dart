/// A product/menu item stored under `stores/{storeId}/products/{productId}`.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;

  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.category = '',
    this.imageUrl = '',
    this.isAvailable = true,
  });

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
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
      };

  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}
