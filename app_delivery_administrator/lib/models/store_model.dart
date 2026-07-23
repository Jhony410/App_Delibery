import 'package:cloud_firestore/cloud_firestore.dart';

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
  // Added for the admin stores CRUD (English keys kept to stay compatible
  // with the data the customer/courier apps write to `stores/`).
  final String? description;
  final String? email;
  final String? contacto;
  final String? ruc;
  final String? imagenUrl;
  /// Google Maps share link for the store's exact location. Stored as-is (a raw
  /// string, no coordinate parsing) so the courier app can later open it.
  /// Kept for back-compat; the map picker now writes [latitude]/[longitude]
  /// instead, but both can coexist.
  final String? mapsUrl;
  /// Real geographic coordinates of the store, set via the map picker. Nullable
  /// so stores created before this field existed keep working. Both are either
  /// present together or both null.
  final double? latitude;
  final double? longitude;
  /// Account status: true = comercio activo, false = pausado/suspendido.
  /// Distinct from [isOpen], which reflects whether it's currently open for
  /// orders based on its hours.
  final bool activo;
  /// Newly registered comercio awaiting admin approval ("Pendientes alta").
  final bool pendingApproval;
  /// Opening hours keyed by day id (mon..sun): {open, close, closed}.
  final Map<String, dynamic>? horarios;
  final DateTime? createdAt;
  final DateTime? commissionUpdatedAt;

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
    this.description,
    this.email,
    this.contacto,
    this.ruc,
    this.imagenUrl,
    this.mapsUrl,
    this.latitude,
    this.longitude,
    this.activo = true,
    this.pendingApproval = false,
    this.horarios,
    this.createdAt,
    this.commissionUpdatedAt,
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
        description: m['description'],
        email: m['email'],
        contacto: m['contacto'],
        ruc: m['ruc'],
        imagenUrl: m['imagenUrl'] ?? m['imagen_url'],
        mapsUrl: m['mapsUrl'],
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        // Default to active when the field is absent so existing stores
        // (written before this field existed) keep showing as "Activo".
        activo: m['activo'] ?? true,
        pendingApproval: m['pendingApproval'] ?? false,
        horarios: (m['horarios'] as Map?)?.cast<String, dynamic>(),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        commissionUpdatedAt:
            (m['commissionUpdatedAt'] as Timestamp?)?.toDate(),
      );

  /// Serializes the editable/persistable fields. `createdAt` is intentionally
  /// omitted — `StoreService.createStore` sets it with a server timestamp.
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
        if (promo != null) 'promo': promo,
        'tone': tone,
        if (district != null) 'district': district,
        if (phone != null) 'phone': phone,
        if (commissionPct != null) 'commissionPct': commissionPct,
        if (description != null) 'description': description,
        if (email != null) 'email': email,
        if (contacto != null) 'contacto': contacto,
        if (ruc != null) 'ruc': ruc,
        if (imagenUrl != null) 'imagenUrl': imagenUrl,
        if (mapsUrl != null) 'mapsUrl': mapsUrl,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'activo': activo,
        'pendingApproval': pendingApproval,
        if (horarios != null) 'horarios': horarios,
      };

  StoreModel copyWith({
    String? name,
    String? category,
    String? categorySlug,
    double? rating,
    int? reviewCount,
    String? deliveryTime,
    double? deliveryFee,
    bool? isOpen,
    String? address,
    String? promo,
    String? tone,
    String? district,
    String? phone,
    double? commissionPct,
    double? monthSales,
    String? description,
    String? email,
    String? contacto,
    String? ruc,
    String? imagenUrl,
    String? mapsUrl,
    double? latitude,
    double? longitude,
    bool? activo,
    bool? pendingApproval,
    Map<String, dynamic>? horarios,
    DateTime? createdAt,
    DateTime? commissionUpdatedAt,
  }) =>
      StoreModel(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        categorySlug: categorySlug ?? this.categorySlug,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        deliveryTime: deliveryTime ?? this.deliveryTime,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        isOpen: isOpen ?? this.isOpen,
        address: address ?? this.address,
        promo: promo ?? this.promo,
        tone: tone ?? this.tone,
        district: district ?? this.district,
        phone: phone ?? this.phone,
        commissionPct: commissionPct ?? this.commissionPct,
        monthSales: monthSales ?? this.monthSales,
        description: description ?? this.description,
        email: email ?? this.email,
        contacto: contacto ?? this.contacto,
        ruc: ruc ?? this.ruc,
        imagenUrl: imagenUrl ?? this.imagenUrl,
        mapsUrl: mapsUrl ?? this.mapsUrl,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        activo: activo ?? this.activo,
        pendingApproval: pendingApproval ?? this.pendingApproval,
        horarios: horarios ?? this.horarios,
        createdAt: createdAt ?? this.createdAt,
        commissionUpdatedAt: commissionUpdatedAt ?? this.commissionUpdatedAt,
      );
}
