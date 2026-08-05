import 'package:flutter/foundation.dart';

import '../delivery_config.dart';
import '../models/order_model.dart';

/// A single line in the cart. Each entry carries its own store data, so the
/// cart can hold items from several stores at the same time (multi-store cart).
class CartEntry {
  final String productId;
  final String name;
  final String? note;
  final String tone;
  final String? imageUrl;
  final double unitPrice;
  int qty;

  // Store this item belongs to. Stamped at add-time from the store being
  // browsed, so items keep their origin even when the user moves on to
  // another store.
  final String storeId;
  final String storeName;
  final String storeTone;
  final String? deliveryTime;
  final double deliveryFee;

  CartEntry({
    required this.productId,
    required this.name,
    this.note,
    required this.tone,
    this.imageUrl,
    required this.unitPrice,
    this.qty = 1,
    required this.storeId,
    required this.storeName,
    required this.storeTone,
    this.deliveryTime,
    required this.deliveryFee,
  });

  double get lineTotal => unitPrice * qty;
}

/// Alias matching the product spec — `CartEntry` already holds every field a
/// `CartItem` needs (productId, productName/name, price/unitPrice, quantity/qty,
/// storeId, storeName, deliveryFee).
typedef CartItem = CartEntry;

/// All items belonging to one store, used to render the cart grouped by store.
class CartGroup {
  final String storeId;
  final String storeName;
  final String storeTone;
  final String? deliveryTime;
  final double deliveryFee;
  final List<CartEntry> items;

  CartGroup({
    required this.storeId,
    required this.storeName,
    required this.storeTone,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.items,
  });

  double get subtotal => items.fold(0.0, (s, e) => s + e.lineTotal);
  double get total => subtotal + deliveryFee;
  int get itemCount => items.fold(0, (s, e) => s + e.qty);
}

/// In-memory cart (static singleton — the app uses no state-management library).
/// The cart holds products from a SINGLE store at a time (enforced by the
/// screens via [canAddFromStore]); the per-store grouping helpers are retained
/// so the cart UI keeps working and resolve to one group. The `store*` fields
/// below describe only the store currently being browsed; they are stamped onto
/// each new [CartEntry] and used by the store/product screens for context.
class CartService {
  /// Emits after every cart mutation so all cart entry points stay synchronized.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  // ── Current browsing context (the store screen the user is looking at) ──
  static String? storeId;
  static String? storeName;
  static String? storeTone;
  static String? deliveryTime;
  static double currentDeliveryFee = 0;

  // ── Cart contents (across all stores) ──
  static final List<CartEntry> items = [];

  static String selectedAddress = '';
  static String? selectedAddressLabel;
  static String? selectedAddressRef;
  // Coordinates of the delivery address the customer picked at checkout. Stamped
  // in cart_screen from the chosen AddressModel so they survive into the order.
  // Null when the selected address has no coordinates saved.
  static double? selectedAddressLat;
  static double? selectedAddressLng;
  static String? lastDeliveryTime;

  /// Sets the store the user is currently browsing. Does NOT clear the cart —
  /// items from previously visited stores must survive navigation.
  static void setStore({
    required String id,
    required String name,
    required String tone,
    required String time,
    required double fee,
  }) {
    storeId = id;
    storeName = name;
    storeTone = tone;
    deliveryTime = time;
    currentDeliveryFee = DeliveryConfig.fixedFee;
  }

  static void addOrIncrement(CartEntry entry) {
    // Only identical configurations merge. Different size/extras are encoded
    // in name, note and unit price and must remain separate cart lines.
    final idx = items.indexWhere(
      (e) =>
          e.productId == entry.productId &&
          e.storeId == entry.storeId &&
          e.name == entry.name &&
          e.note == entry.note &&
          e.unitPrice == entry.unitPrice,
    );
    if (idx >= 0) {
      items[idx].qty += entry.qty;
    } else {
      items.add(entry);
    }
    _notify();
  }

  // ── Single-store enforcement ──────────────────────────────────────────────
  // The cart may only hold products from ONE store at a time (like Rappi /
  // PedidosYa). The grouping helpers below (`groups`, `CartGroup`) still work —
  // with the invariant they simply resolve to a single group — so they are kept
  // for the cart UI. The screens call [canAddFromStore] before adding and, on a
  // conflict, prompt the user to empty the cart first.

  /// The store the cart currently belongs to, or null when it is empty.
  static String? get cartStoreId => items.isEmpty ? null : items.first.storeId;

  /// The name of the store the cart currently belongs to (empty cart → null).
  static String? get cartStoreName =>
      items.isEmpty ? null : items.first.storeName;

  /// The tone of the store the cart currently belongs to (empty cart → null).
  static String? get cartStoreTone =>
      items.isEmpty ? null : items.first.storeTone;

  /// The delivery time stamped on the cart's items (empty cart → falls back to
  /// the browsing context). Prefer this over the mutable browsing `deliveryTime`
  /// when showing checkout info, so it reflects the store actually purchased
  /// from — not whatever store was opened last.
  static String? get cartDeliveryTime =>
      items.isEmpty ? deliveryTime : items.first.deliveryTime;

  /// Whether a product from [storeId] can be added without mixing stores.
  /// True when the cart is empty or already belongs to that same store.
  static bool canAddFromStore(String storeId) =>
      items.isEmpty || cartStoreId == storeId;

  static void incrementEntry(CartEntry entry) {
    entry.qty++;
    _notify();
  }

  static void decrementEntry(CartEntry entry) {
    if (entry.qty > 1) {
      entry.qty--;
    } else {
      items.remove(entry);
    }
    _notify();
  }

  static void removeEntry(CartEntry entry) {
    items.remove(entry);
    _notify();
  }

  static void setDeliveryAddress({
    required String street,
    String? label,
    String? reference,
    double? latitude,
    double? longitude,
  }) {
    selectedAddress = street;
    selectedAddressLabel = label;
    selectedAddressRef = reference;
    selectedAddressLat = latitude;
    selectedAddressLng = longitude;
    _notify();
  }

  static void clear() {
    lastDeliveryTime = deliveryTime;
    items.clear();
    storeId = null;
    storeName = null;
    storeTone = null;
    deliveryTime = null;
    currentDeliveryFee = 0;
    selectedAddressLat = null;
    selectedAddressLng = null;
    _notify();
  }

  static void _notify() => revision.value++;

  /// Cart items grouped by store, preserving first-seen order.
  static List<CartGroup> get groups {
    final map = <String, CartGroup>{};
    for (final e in items) {
      final g = map.putIfAbsent(
        e.storeId,
        () => CartGroup(
          storeId: e.storeId,
          storeName: e.storeName,
          storeTone: e.storeTone,
          deliveryTime: e.deliveryTime,
          deliveryFee: DeliveryConfig.fixedFee,
          items: [],
        ),
      );
      g.items.add(e);
    }
    return map.values.toList();
  }

  static int get itemCount => items.fold(0, (s, e) => s + e.qty);
  static double get subtotal => items.fold(0.0, (s, e) => s + e.lineTotal);

  /// One fixed delivery fee per order. Empty carts do not display a fee.
  static double get deliveryFee => items.isEmpty ? 0 : DeliveryConfig.fixedFee;

  static double get total => subtotal + deliveryFee;

  static List<OrderItem> toOrderItems() => items
      .map(
        (e) => OrderItem(
          productId: e.productId,
          name: e.name,
          qty: e.qty,
          price: e.unitPrice,
          note: e.note,
        ),
      )
      .toList();
}
