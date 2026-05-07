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
        productId: m['productId'],
        name: m['name'],
        qty: m['qty'],
        price: (m['price'] as num).toDouble(),
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
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String address;
  final String paymentMethod;
  final String? observation;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.storeTone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.address,
    required this.paymentMethod,
    this.observation,
    required this.createdAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) => OrderModel(
        id: id,
        userId: m['userId'],
        storeId: m['storeId'],
        storeName: m['storeName'],
        storeTone: m['storeTone'] ?? 'warm',
        items: (m['items'] as List)
            .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
            .toList(),
        subtotal: (m['subtotal'] as num).toDouble(),
        deliveryFee: (m['deliveryFee'] as num).toDouble(),
        total: (m['total'] as num).toDouble(),
        status: m['status'],
        address: m['address'],
        paymentMethod: m['paymentMethod'],
        observation: m['observation'] as String?,
        createdAt: (m['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'storeId': storeId,
        'storeName': storeName,
        'storeTone': storeTone,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': status,
        'courierId': null,
        'address': address,
        'paymentMethod': paymentMethod,
        if (observation != null && observation!.isNotEmpty)
          'observation': observation,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // pending | confirmed | preparing | en_camino | entregado | cancelado
  String get statusLabel => switch (status) {
        'en_camino' => 'En camino',
        'entregado' => 'Entregado',
        'cancelado' => 'Cancelado',
        'preparing' => 'Preparando',
        'confirmed' => 'Confirmado',
        _ => 'Pendiente',
      };
}
