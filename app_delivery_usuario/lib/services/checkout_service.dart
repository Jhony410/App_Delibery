import '../models/order_model.dart';
import '../models/store_model.dart';
import 'auth_service.dart';
import 'cart_service.dart';
import 'db_service.dart';

class CheckoutException implements Exception {
  final String code;
  final String message;

  const CheckoutException(this.message, {this.code = 'checkout'});

  @override
  String toString() => message;
}

class CheckoutService {
  static bool _creatingOrder = false;

  static bool get isCreatingOrder => _creatingOrder;

  static Future<String> createOrder({
    required String paymentMethod,
    String? observation,
  }) async {
    if (_creatingOrder) {
      throw const CheckoutException('El pedido ya se está procesando.');
    }

    final uid = AuthService.currentUid;
    if (uid == null) {
      throw const CheckoutException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }
    if (CartService.items.isEmpty) {
      throw const CheckoutException('Tu carrito está vacío.');
    }
    if (CartService.selectedAddress.trim().isEmpty) {
      throw const CheckoutException('Selecciona una dirección de entrega.');
    }
    if (paymentMethod != 'yape' && paymentMethod != 'cash') {
      throw const CheckoutException('Selecciona un método de pago válido.');
    }

    final profile = await DbService.getUser(uid);
    if (profile == null) {
      throw const CheckoutException(
        'No pudimos cargar tu perfil. Vuelve a iniciar sesión.',
        code: 'missing-profile',
      );
    }
    if (profile.phone.trim().isEmpty) {
      throw const CheckoutException(
        'Agrega un celular de contacto para coordinar la entrega.',
        code: 'missing-phone',
      );
    }

    _creatingOrder = true;
    try {
      final storeId = CartService.cartStoreId ?? '';
      StoreModel? store;
      try {
        store = await DbService.getStore(storeId);
      } catch (_) {
        store = null;
      }
      if (store != null && !store.isOpen) {
        throw const CheckoutException(
          'El comercio está cerrado. Tu carrito sigue guardado.',
        );
      }

      final note = observation?.trim();
      final order = OrderModel(
        id: '',
        userId: uid,
        storeId: storeId,
        storeName: CartService.cartStoreName ?? '',
        storeTone: CartService.cartStoreTone ?? 'warm',
        storeAddress: store?.address,
        storePhone: store?.phone,
        storeLat: store?.latitude,
        storeLng: store?.longitude,
        deliveryLat: CartService.selectedAddressLat,
        deliveryLng: CartService.selectedAddressLng,
        items: CartService.toOrderItems(),
        subtotal: CartService.subtotal,
        deliveryFee: CartService.deliveryFee,
        total: CartService.total,
        status: 'confirmed',
        address: CartService.selectedAddress,
        paymentMethod: paymentMethod,
        observation: note == null || note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      );
      final orderId = await DbService.createOrder(order);
      CartService.clear();
      return orderId;
    } finally {
      _creatingOrder = false;
    }
  }
}
