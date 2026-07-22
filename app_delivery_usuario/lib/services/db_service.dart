import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
import '../models/favorite_model.dart';
import '../models/notification_model.dart';

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

  /// Flags an order as rated so the "Calificar" action is only offered once.
  static Future<void> markOrderRated(String orderId) =>
      _db.collection('orders').doc(orderId).update({'rated': true});

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

  /// Live view of the `users/{uid}` doc so profile stats refresh on their own.
  static Stream<UserModel?> streamUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? UserModel.fromMap(uid, d.data()!) : null);

  // ── Favorites ─────────────────────────────────────────────
  static Future<List<FavoriteModel>> getUserFavorites(String uid) async {
    final snap =
        await _db.collection('users').doc(uid).collection('favorites').get();
    return snap.docs.map((d) => FavoriteModel.fromMap(d.id, d.data())).toList();
  }

  static Stream<List<FavoriteModel>> streamUserFavorites(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => FavoriteModel.fromMap(d.id, d.data())).toList());

  static Future<bool> isFavorite(String uid, String storeId) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(storeId)
        .get();
    return doc.exists;
  }

  /// Adds or removes `users/{uid}/favorites/{storeId}`. Returns the resulting
  /// favourite state (true = now a favourite). The doc id is the storeId so the
  /// operation is idempotent.
  static Future<bool> toggleFavorite(
      String uid, String storeId, String storeName) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(storeId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      return false;
    }
    await ref.set(
        FavoriteModel(storeId: storeId, storeName: storeName).toMap());
    return true;
  }

  // ── Notifications ─────────────────────────────────────────
  static Stream<List<NotificationModel>> streamUserNotifications(String uid) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => NotificationModel.fromMap(d.id, d.data()))
              .toList());

  static Stream<int> countUnreadNotifications(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

  static Future<void> markNotificationRead(String uid, String notificationId) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

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

  /// The address marked as default, or the first saved one if none is marked.
  /// Returns null when the user has no saved addresses.
  static Future<AddressModel?> getDefaultAddress(String uid) async {
    final list = await getUserAddresses(uid);
    if (list.isEmpty) return null;
    for (final a in list) {
      if (a.isDefault) return a;
    }
    return list.first;
  }

  static Future<void> addAddress(String uid, AddressModel address) =>
      _db.collection('users').doc(uid).collection('addresses').add(address.toMap());

  static Future<void> updateAddress(
          String uid, String addressId, AddressModel address) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .update(address.toMap());

  /// Marks [addressId] as the default one, clearing the flag on every other
  /// saved address in a single atomic batch so only one stays true.
  static Future<void> setDefaultAddress(String uid, String addressId) async {
    final col = _db.collection('users').doc(uid).collection('addresses');
    final snap = await col.get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

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
