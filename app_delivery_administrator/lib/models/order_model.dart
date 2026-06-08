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
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String address;
  final String paymentMethod;
  final String? observation;
  final String? courierId;
  final String? courierName;
  // Round-robin dispatch: courier currently being offered the order and when
  // that 15s offer lapses. Null when no offer is outstanding.
  final String? assignedCourierId;
  final DateTime? assignmentExpiresAt;
  final double? distanceKm;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? expiresAt;

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
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.address,
    required this.paymentMethod,
    this.observation,
    this.courierId,
    this.courierName,
    this.assignedCourierId,
    this.assignmentExpiresAt,
    this.distanceKm,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.expiresAt,
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
        items: (m['items'] as List? ?? [])
            .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i as Map)))
            .toList(),
        subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (m['deliveryFee'] as num?)?.toDouble() ?? 0,
        total: (m['total'] as num?)?.toDouble() ?? 0,
        status: m['status'] ?? 'pending',
        address: m['address'] ?? '',
        paymentMethod: m['paymentMethod'] ?? 'efectivo',
        observation: m['observation'] as String?,
        courierId: m['courierId'] as String?,
        courierName: m['courierName'] as String?,
        assignedCourierId: m['assignedCourierId'] as String?,
        assignmentExpiresAt:
            (m['assignmentExpiresAt'] as Timestamp?)?.toDate(),
        distanceKm: (m['distanceKm'] as num?)?.toDouble(),
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        acceptedAt: (m['acceptedAt'] as Timestamp?)?.toDate(),
        pickedUpAt: (m['pickedUpAt'] as Timestamp?)?.toDate(),
        deliveredAt: (m['deliveredAt'] as Timestamp?)?.toDate(),
        cancelledAt: (m['cancelledAt'] as Timestamp?)?.toDate(),
        expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
      );

  String get statusLabel => switch (status) {
        'pending' => 'Pendiente',
        'confirmed' => 'Confirmado',
        'preparing' => 'Preparando',
        'accepted' => 'Aceptado',
        'picked_up' => 'Recogido',
        'en_camino' => 'En camino',
        'entregado' => 'Entregado',
        'cancelado' => 'Cancelado',
        'searching' => 'Buscando rep.',
        'sin_repartidor' => 'Sin repartidor',
        _ => status,
      };

  /// Tone used by the Badge widget.
  String get statusTone => switch (status) {
        'en_camino' || 'accepted' || 'picked_up' => 'green',
        'preparing' || 'confirmed' || 'searching' => 'amber',
        'cancelado' || 'sin_repartidor' => 'red',
        'entregado' => 'gray',
        _ => 'gray',
      };

  bool get isActive =>
      status != 'entregado' && status != 'cancelado';
}
