import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/product_model.dart';
import '../services/db_service.dart';
import '../services/cart_service.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _sizeIdx = 0;
  List<bool> _extras = [];
  List<bool> _cutlery = [];
  int _qty = 1;
  String? _storeId;
  String? _productId;
  Future<ProductModel?> _future = Future.value(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    if (args != null &&
        (args['storeId'] != _storeId || args['productId'] != _productId)) {
      _storeId = args['storeId'];
      _productId = args['productId'];
      _future = DbService.getProduct(_storeId!, _productId!);
    }
  }

  double _computePrice(ProductModel product) {
    final base = product.sizes.isNotEmpty
        ? product.sizes[_sizeIdx].price
        : product.price;
    final extrasTotal = product.extras.asMap().entries
        .where((e) => e.key < _extras.length && _extras[e.key])
        .fold(0.0, (sum, e) => sum + e.value.price);
    final cutleryTotal = product.cutlery.asMap().entries
        .where((e) => e.key < _cutlery.length && _cutlery[e.key])
        .fold(0.0, (sum, e) => sum + e.value.price);
    return (base + extrasTotal + cutleryTotal) * _qty;
  }

  void _addToCart(ProductModel product) {
    final sizeName = product.sizes.isNotEmpty
        ? ' (${product.sizes[_sizeIdx].name})'
        : '';
    final selectedExtras = product.extras.asMap().entries
        .where((e) => e.key < _extras.length && _extras[e.key])
        .map((e) => e.value.name)
        .join(', ');
    final selectedCutlery = product.cutlery.asMap().entries
        .where((e) => e.key < _cutlery.length && _cutlery[e.key])
        .map((e) => e.value.name)
        .join(', ');
    // Human-readable selection, stored in `note`. This is the only channel the
    // courier and admin apps already read, so it keeps the choice visible there
    // without touching those apps.
    final noteParts = <String>[
      if (selectedExtras.isNotEmpty) selectedExtras,
      if (selectedCutlery.isNotEmpty) 'Cubiertos: $selectedCutlery',
    ];
    CartService.addOrIncrement(CartEntry(
      productId: product.id,
      name: '${product.name}$sizeName',
      note: noteParts.isEmpty ? null : noteParts.join(' · '),
      tone: product.tone,
      unitPrice: _computePrice(product) / _qty,
      qty: _qty,
      storeId: CartService.storeId ?? product.storeId,
      storeName: CartService.storeName ?? '',
      storeTone: CartService.storeTone ?? product.tone,
      deliveryTime: CartService.deliveryTime,
      deliveryFee: CartService.currentDeliveryFee,
    ));
    // Non-blocking feedback — keep the user on the screen so they can keep
    // browsing and adding more products. Navigation to the cart is explicit
    // (the floating "Ver carrito" bar on the store screen).
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Agregado al carrito · ${product.name}'),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.appText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductModel?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        final product = snap.data;
        if (product == null) {
          return const Scaffold(
            body: Center(child: Text('Producto no encontrado')),
          );
        }
        if (_extras.length != product.extras.length) {
          _extras = List.filled(product.extras.length, false);
        }
        if (_cutlery.length != product.cutlery.length) {
          _cutlery = List.filled(product.cutlery.length, false);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      ImgPlaceholder(
                        label: 'FOTO DE PRODUCTO · GRANDE',
                        height: 340,
                        radius: 0,
                        tone: product.tone,
                        assetPath: assetForKey(product.id),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 20,
                        child: _OverlayBtn(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.chevron_left, size: 22),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: 20,
                        child: const _OverlayBtn(
                          child: Icon(Icons.favorite_border, size: 20),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (CartService.storeName != null)
                            Text(
                              CartService.storeName!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.06,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            product.name,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.48,
                                height: 1.15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted,
                                height: 1.5),
                          ),
                          if (product.sizes.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tamaño',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                                Text('Obligatorio · 1',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...product.sizes.asMap().entries.map((e) {
                              final sel = e.key == _sizeIdx;
                              return GestureDetector(
                                onTap: () => setState(() => _sizeIdx = e.key),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 1.5,
                                    ),
                                    color: sel
                                        ? AppColors.primaryTint
                                        : Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: sel
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: 2,
                                          ),
                                        ),
                                        child: sel
                                            ? Center(
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(e.value.name,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      Text(
                                          'S/ ${e.value.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                          if (product.extras.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Extras',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                                Text('Opcional',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...product.extras.asMap().entries.map((e) {
                              final sel = e.key < _extras.length && _extras[e.key];
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _extras[e.key] = !_extras[e.key]),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? AppColors.primary
                                              : Colors.white,
                                          border: Border.all(
                                            color: sel
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: sel
                                            ? const Icon(Icons.check,
                                                size: 14, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(e.value.name,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                      Text(
                                          e.value.price == 0
                                              ? 'Gratis'
                                              : '+${e.value.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                          if (product.cutlery.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Cubiertos',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                                Text('Opcional',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...product.cutlery.asMap().entries.map((e) {
                              final sel =
                                  e.key < _cutlery.length && _cutlery[e.key];
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _cutlery[e.key] = !_cutlery[e.key]),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? AppColors.primary
                                              : Colors.white,
                                          border: Border.all(
                                            color: sel
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: sel
                                            ? const Icon(Icons.check,
                                                size: 14, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(e.value.name,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                      Text(
                                          e.value.price == 0
                                              ? 'Gratis'
                                              : '+${e.value.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_qty > 1) setState(() => _qty--);
                              },
                              child: const SizedBox(
                                  width: 40,
                                  child: Icon(Icons.remove, size: 18)),
                            ),
                            Text('$_qty',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            GestureDetector(
                              onTap: () => setState(() => _qty++),
                              child: const SizedBox(
                                  width: 40,
                                  child: Icon(Icons.add,
                                      size: 18, color: AppColors.primary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label:
                              'Agregar · S/ ${_computePrice(product).toStringAsFixed(2)}',
                          onTap: () => _addToCart(product),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _OverlayBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
