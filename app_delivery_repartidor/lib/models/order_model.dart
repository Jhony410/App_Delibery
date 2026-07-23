import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int qty;
  final double price;
  final String? note;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
    this.note,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] ?? '',
        name: m['name'] ?? '',
        qty: m['qty'] ?? 1,
        price: (m['price'] as num?)?.toDouble() ?? 0,
        note: m['note'],
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'qty': qty,
        'price': price,
        'note': note,
      };
}

class OrderModel {
  final String id;
  final String userId;
  final String storeId;
  final String storeName;
  final String storeTone;
  final String? storeAddress;
  final String? storePhone;
  final String? customerName;
  final String? customerPhone;
  // Coordinates propagated by the customer app at order creation. All nullable:
  // orders created before this existed, or from stores/addresses without
  // coordinates, carry null and the route screens degrade to text-only.
  final double? storeLat;
  final double? storeLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String address;
  final String paymentMethod;
  final String? observation;
  final String? courierId;
  final double? distanceKm;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  // Round-robin dispatch: the courier this order is currently being offered to
  // and when that 15s offer lapses. Null when no offer is outstanding.
  final String? assignedCourierId;
  final DateTime? assignmentExpiresAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.storeTone,
    this.storeAddress,
    this.storePhone,
    this.customerName,
    this.customerPhone,
    this.storeLat,
    this.storeLng,
    this.deliveryLat,
    this.deliveryLng,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.address,
    required this.paymentMethod,
    this.observation,
    this.courierId,
    this.distanceKm,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.assignedCourierId,
    this.assignmentExpiresAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) => OrderModel(
        id: id,
        userId: m['userId'] ?? '',
        storeId: m['storeId'] ?? '',
        storeName: m['storeName'] ?? '',
        storeTone: m['storeTone'] ?? 'warm',
        storeAddress: m['storeAddress'],
        storePhone: m['storePhone'],
        customerName: m['customerName'],
        customerPhone: m['customerPhone'],
        storeLat: (m['storeLat'] as num?)?.toDouble(),
        storeLng: (m['storeLng'] as num?)?.toDouble(),
        deliveryLat: (m['deliveryLat'] as num?)?.toDouble(),
        deliveryLng: (m['deliveryLng'] as num?)?.toDouble(),
        items: (m['items'] as List? ?? [])
            .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
            .toList(),
        subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (m['deliveryFee'] as num?)?.toDouble() ?? 0,
        total: (m['total'] as num?)?.toDouble() ?? 0,
        status: m['status'] ?? 'pending',
        address: m['address'] ?? '',
        paymentMethod: m['paymentMethod'] ?? 'efectivo',
        observation: m['observation'] as String?,
        courierId: m['courierId'] as String?,
        distanceKm: (m['distanceKm'] as num?)?.toDouble(),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        acceptedAt: (m['acceptedAt'] as Timestamp?)?.toDate(),
        pickedUpAt: (m['pickedUpAt'] as Timestamp?)?.toDate(),
        deliveredAt: (m['deliveredAt'] as Timestamp?)?.toDate(),
        assignedCourierId: m['assignedCourierId'] as String?,
        assignmentExpiresAt: (m['assignmentExpiresAt'] as Timestamp?)?.toDate(),
      );

  // Status flow for courier:
  // pending → confirmed → preparing → accepted → picked_up → en_camino → entregado | cancelado
  String get statusLabel => switch (status) {
        'accepted' => 'Aceptado',
        'picked_up' => 'Recogido',
        'en_camino' => 'En camino',
        'entregado' => 'Entregado',
        'cancelado' => 'Cancelado',
        'preparing' => 'Preparando',
        'confirmed' => 'Confirmado',
        _ => 'Pendiente',
      };

  bool get isCash => paymentMethod.toLowerCase().contains('efectivo') ||
      paymentMethod.toLowerCase().contains('cash');

  // Estimated courier earning (used for the home + completed views).
  double get courierEarning => deliveryFee > 0 ? deliveryFee : 8.0;
}
