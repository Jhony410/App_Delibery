import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';

class DbService {
  static final _db = FirebaseFirestore.instance;

  // ── Stores ────────────────────────────────────────────────
  static Future<List<StoreModel>> getStores({String? categorySlug}) async {
    Query<Map<String, dynamic>> q =
        _db.collection('stores').where('isOpen', isEqualTo: true);
    if (categorySlug != null) {
      q = q.where('categorySlug', isEqualTo: categorySlug);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => StoreModel.fromMap(d.id, d.data()))
        .toList();
  }

  static Future<StoreModel?> getStore(String storeId) async {
    final doc = await _db.collection('stores').doc(storeId).get();
    if (!doc.exists) return null;
    return StoreModel.fromMap(doc.id, doc.data()!);
  }

  static Future<List<StoreModel>> searchStores(String query) async {
    final snap = await _db.collection('stores').get();
    final q = query.toLowerCase();
    return snap.docs
        .map((d) => StoreModel.fromMap(d.id, d.data()))
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q))
        .toList();
  }

  // ── Products ──────────────────────────────────────────────
  static Future<List<ProductModel>> getStoreProducts(
      String storeId, {String? category}) async {
    Query<Map<String, dynamic>> q = _db
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .where('isAvailable', isEqualTo: true);
    if (category != null) q = q.where('category', isEqualTo: category);
    final snap = await q.get();
    return snap.docs
        .map((d) => ProductModel.fromMap(d.id, storeId, d.data()))
        .toList();
  }

  static Future<ProductModel?> getProduct(
      String storeId, String productId) async {
    final doc = await _db
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.id, storeId, doc.data()!);
  }

  // ── Orders ────────────────────────────────────────────────
  static Future<String> createOrder(OrderModel order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    await _db.collection('users').doc(order.userId).update({
      'totalOrders': FieldValue.increment(1),
      'totalSpent': FieldValue.increment(order.total),
    });
    return ref.id;
  }

  static Future<List<OrderModel>> getUserOrders(String userId) async {
    final snap = await _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
  }

  static Stream<List<OrderModel>> streamUserOrders(String userId) =>
      _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());

  static Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.id, doc.data()!);
  }

  static Stream<OrderModel?> streamOrder(String orderId) =>
      _db.collection('orders').doc(orderId).snapshots().map(
            (doc) => doc.exists
                ? OrderModel.fromMap(doc.id, doc.data()!)
                : null,
          );

  static Future<void> updateOrderStatus(String orderId, String status) =>
      _db.collection('orders').doc(orderId).update({'status': status});

  // ── Couriers (read-only; owned by the courier app) ────────
  /// Live view of the courier assigned to an order, so the tracking screen can
  /// show the real driver instead of a placeholder. Returns null until a
  /// courier accepts (order.courierId still null) or if the doc is missing.
  static Stream<CourierInfo?> streamCourier(String courierId) => _db
      .collection('couriers')
      .doc(courierId)
      .snapshots()
      .map((d) => d.exists ? CourierInfo.fromMap(d.id, d.data()!) : null);

  // ── Users ─────────────────────────────────────────────────
  static Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ── Addresses ─────────────────────────────────────────────
  static Future<List<AddressModel>> getUserAddresses(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .get();
    return snap.docs
        .map((d) => AddressModel.fromMap(d.id, d.data()))
        .toList();
  }

  static Future<void> addAddress(String uid, AddressModel address) =>
      _db.collection('users').doc(uid).collection('addresses').add(address.toMap());

  static Future<void> deleteAddress(String uid, String addressId) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .delete();
}

/// Read-only projection of a `couriers/{uid}` doc — only the fields the customer
/// app needs to render the "your courier" card on the tracking screen.
class CourierInfo {
  final String uid;
  final String name;
  final String phone;
  final String vehicleModel;
  final String vehiclePlate;
  final double rating;
  final int totalDeliveries;

  const CourierInfo({
    required this.uid,
    required this.name,
    required this.phone,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.rating,
    required this.totalDeliveries,
  });

  factory CourierInfo.fromMap(String uid, Map<String, dynamic> m) => CourierInfo(
        uid: uid,
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        vehicleModel: m['vehicleModel'] ?? '',
        vehiclePlate: m['vehiclePlate'] ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        totalDeliveries: m['totalDeliveries'] ?? 0,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'R';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
