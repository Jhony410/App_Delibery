import '../models/order_model.dart';

class CartEntry {
  final String productId;
  final String name;
  final String? note;
  final String tone;
  final double unitPrice;
  int qty;

  CartEntry({
    required this.productId,
    required this.name,
    this.note,
    required this.tone,
    required this.unitPrice,
    this.qty = 1,
  });

  double get lineTotal => unitPrice * qty;
}

class CartService {
  static String? storeId;
  static String? storeName;
  static String? storeTone;
  static String? deliveryTime;
  static double deliveryFee = 0;
  static final List<CartEntry> items = [];
  static String selectedAddress = 'Av. Arequipa 2450, Lince';
  static String? selectedAddressRef;
  static String? lastDeliveryTime;

  static void setStore({
    required String id,
    required String name,
    required String tone,
    required String time,
    required double fee,
  }) {
    if (storeId != id) items.clear();
    storeId = id;
    storeName = name;
    storeTone = tone;
    deliveryTime = time;
    deliveryFee = fee;
  }

  static void addOrIncrement(CartEntry entry) {
    final idx = items.indexWhere((e) => e.productId == entry.productId);
    if (idx >= 0) {
      items[idx].qty += entry.qty;
    } else {
      items.add(entry);
    }
  }

  static void increment(int idx) => items[idx].qty++;

  static void decrement(int idx) {
    if (items[idx].qty > 1) {
      items[idx].qty--;
    } else {
      items.removeAt(idx);
    }
  }

  static void clear() {
    lastDeliveryTime = deliveryTime;
    items.clear();
    storeId = null;
    storeName = null;
    storeTone = null;
    deliveryTime = null;
    deliveryFee = 0;
  }

  static int get itemCount => items.fold(0, (s, e) => s + e.qty);
  static double get subtotal => items.fold(0.0, (s, e) => s + e.lineTotal);
  static double get total => subtotal + deliveryFee;

  static List<OrderItem> toOrderItems() => items
      .map((e) => OrderItem(
            productId: e.productId,
            name: e.name,
            qty: e.qty,
            price: e.lineTotal,
            note: e.note,
          ))
      .toList();
}
