import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../models/store_model.dart';

/// Aggregated sales figures for a single store over the current calendar month.
class StoreMonthStats {
  final int orders;
  final double gross;
  final double commission;
  final double payout;
  final int cancellations;
  final double cancelRate;
  /// Gross sales per day-of-month (index 1..31; index 0 unused).
  final List<double> dailyGross;

  const StoreMonthStats({
    required this.orders,
    required this.gross,
    required this.commission,
    required this.payout,
    required this.cancellations,
    required this.cancelRate,
    required this.dailyGross,
  });

  static const empty = StoreMonthStats(
    orders: 0,
    gross: 0,
    commission: 0,
    payout: 0,
    cancellations: 0,
    cancelRate: 0,
    dailyGross: <double>[],
  );
}

class StoreService {
  static final _col = FirebaseFirestore.instance.collection('stores');
  static final _orders = FirebaseFirestore.instance.collection('orders');

  // ─── Stores ──────────────────────────────────────────────────────
  /// Real-time list of all stores ordered by name.
  static Stream<List<StoreModel>> getStoresStream() {
    return _col.orderBy('name').snapshots().map((s) => s.docs
        .map((d) => StoreModel.fromMap(d.id, d.data()))
        .toList());
  }

  /// Back-compat alias.
  static Stream<List<StoreModel>> streamAll() => getStoresStream();

  static Future<StoreModel?> get(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return StoreModel.fromMap(snap.id, snap.data()!);
  }

  /// Creates a new store document with an auto-generated id.
  static Future<void> createStore(StoreModel store) async {
    final data = store.toMap()..['createdAt'] = FieldValue.serverTimestamp();
    await _col.add(data);
  }

  /// Partial update — only the provided fields are written.
  static Future<void> updateStore(String id, Map<String, dynamic> fields) =>
      _col.doc(id).update(fields);

  /// Toggles the comercio's account status (activo / pausado).
  static Future<void> toggleStoreStatus(String id, bool isActive) =>
      _col.doc(id).update({'activo': isActive});

  static Future<void> deleteStore(String id) => _col.doc(id).delete();

  // Legacy helpers kept for any existing callers.
  static Future<void> updateOpen(String id, bool isOpen) =>
      _col.doc(id).update({'isOpen': isOpen});

  static Future<void> updateCommission(String id, double pct) =>
      _col.doc(id).update({
        'commissionPct': pct,
        'commissionUpdatedAt': FieldValue.serverTimestamp(),
      });

  // ─── Products (stores/{storeId}/products) ────────────────────────
  static CollectionReference<Map<String, dynamic>> _products(String storeId) =>
      _col.doc(storeId).collection('products');

  static Stream<List<ProductModel>> streamProducts(String storeId) {
    return _products(storeId).orderBy('name').snapshots().map((s) => s.docs
        .map((d) => ProductModel.fromMap(d.id, d.data()))
        .toList());
  }

  static Future<void> addProduct(String storeId, ProductModel p) =>
      _products(storeId).add(p.toMap());

  static Future<void> updateProduct(
          String storeId, String productId, Map<String, dynamic> fields) =>
      _products(storeId).doc(productId).update(fields);

  static Future<void> deleteProduct(String storeId, String productId) =>
      _products(storeId).doc(productId).delete();

  // ─── Monthly sales aggregation (from orders) ─────────────────────
  /// Computes this calendar month's figures for [storeId].
  ///
  /// Queries orders by `storeId` only (single-field auto index) and filters
  /// the date range client-side to avoid requiring a composite index.
  static Future<StoreMonthStats> monthStats(
      String storeId, double commissionPct) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final snap =
        await _orders.where('storeId', isEqualTo: storeId).get();

    var gross = 0.0;
    var orders = 0;
    var cancellations = 0;
    final daily = List<double>.filled(daysInMonth + 1, 0);

    for (final doc in snap.docs) {
      final m = doc.data();
      final created = (m['createdAt'] as Timestamp?)?.toDate();
      if (created == null || created.isBefore(start)) continue;
      orders++;
      final status = (m['status'] ?? '') as String;
      if (status == 'cancelado' || status == 'sin_repartidor') {
        cancellations++;
        continue;
      }
      final total = (m['total'] as num?)?.toDouble() ?? 0;
      gross += total;
      if (created.day <= daysInMonth) daily[created.day] += total;
    }

    final commission = gross * commissionPct / 100;
    return StoreMonthStats(
      orders: orders,
      gross: gross,
      commission: commission,
      payout: gross - commission,
      cancellations: cancellations,
      cancelRate: orders == 0 ? 0 : cancellations / orders * 100,
      dailyGross: daily,
    );
  }
}
