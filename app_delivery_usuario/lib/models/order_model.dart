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
  // Pickup location text for the courier app. Written at order creation from
  // the store's StoreModel.address so the courier sees a real address instead
  // of "Dirección no registrada". The courier app reads `storeAddress`.
  final String? storeAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String address;
  final String paymentMethod;
  final String? observation;
  final String? courierId;
  // Name of the courier handling the order, written by the courier app on
  // accept. Lets the tracking card show the driver directly without a
  // couriers/{id} lookup (and survives even if courierId is later cleared).
  final String? courierName;
  // Round-robin offer field (owned by Cloud Functions): the courier currently
  // being offered the order while it is still 'confirmed'. Used as a fallback
  // to resolve the courier's identity for the tracking card.
  final String? assignedCourierId;
  // True once the customer has rated this order (set by the rating screen).
  // Absent on older orders — treated as false when missing.
  final bool rated;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.storeTone,
    this.storeAddress,
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
    this.rated = false,
    required this.createdAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) => OrderModel(
        id: id,
        userId: m['userId'],
        storeId: m['storeId'],
        storeName: m['storeName'],
        storeTone: m['storeTone'] ?? 'warm',
        storeAddress: m['storeAddress'] as String?,
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
        courierId: m['courierId'] as String?,
        courierName: m['courierName'] as String?,
        assignedCourierId: m['assignedCourierId'] as String?,
        rated: m['rated'] ?? false,
        createdAt: (m['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'storeId': storeId,
        'storeName': storeName,
        'storeTone': storeTone,
        if (storeAddress != null && storeAddress!.isNotEmpty)
          'storeAddress': storeAddress,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': status,
        'courierId': courierId,
        'address': address,
        'paymentMethod': paymentMethod,
        if (observation != null && observation!.isNotEmpty)
          'observation': observation,
        'createdAt': Timestamp.fromDate(createdAt),
        // TTL fields for auto-deletion (see Cloud Function autoDeleteExpiredOrders).
        // An un-picked-up order self-expires 30 min after it is created.
        'expiresAt':
            Timestamp.fromDate(createdAt.add(const Duration(minutes: 30))),
        // Set by the admin panel when an order is cancelled; null until then.
        'cancelledAt': null,
        // Round-robin courier dispatch (owned by Cloud Functions + courier app).
        // assignedCourierId: courier currently being offered the order.
        // assignmentExpiresAt: when that 15s offer lapses.
        // rejectedCouriers: couriers that already rejected / timed out.
        'assignedCourierId': null,
        'assignmentExpiresAt': null,
        'rejectedCouriers': <String>[],
      };

  // pending | confirmed | preparing | accepted | picked_up | en_camino
  //         | entregado | cancelado
  String get statusLabel => switch (status) {
        'en_camino' => 'En camino',
        'entregado' => 'Entregado',
        'cancelado' => 'Cancelado',
        'picked_up' => 'Recogido',
        'accepted' => 'Repartidor asignado',
        'preparing' => 'Preparando',
        'confirmed' => 'Confirmado',
        _ => 'Pendiente',
      };
}
