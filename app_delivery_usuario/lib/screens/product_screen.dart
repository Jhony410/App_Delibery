import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/product_model.dart';
import '../services/db_service.dart';
import '../services/cart_service.dart';
import '../delivery_config.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _sizeIdx = -1;
  List<bool> _extras = [];
  List<bool> _cutlery = [];
  int _qty = 1;
  bool _adding = false;
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
    final base = product.sizes.isNotEmpty && _sizeIdx >= 0
        ? product.sizes[_sizeIdx].price
        : product.price;
    final extrasTotal = product.extras
        .asMap()
        .entries
        .where((e) => e.key < _extras.length && _extras[e.key])
        .fold(0.0, (sum, e) => sum + e.value.price);
    final cutleryTotal = product.cutlery
        .asMap()
        .entries
        .where((e) => e.key < _cutlery.length && _cutlery[e.key])
        .fold(0.0, (sum, e) => sum + e.value.price);
    return (base + extrasTotal + cutleryTotal) * _qty;
  }

  Future<void> _addToCart(ProductModel product) async {
    // Store context of the product being added (the store currently browsed).
    // Captured before any clear() so we can re-stamp it if the cart is emptied.
    final storeId = CartService.storeId ?? product.storeId;
    final storeName = CartService.storeName ?? '';
    final storeTone = CartService.storeTone ?? product.tone;
    final deliveryTime = CartService.deliveryTime;
    const deliveryFee = DeliveryConfig.fixedFee;

    // Single-store cart: if the cart already belongs to another store, ask
    // before replacing its contents. Nothing is added unless the user confirms.
    if (!CartService.canAddFromStore(storeId)) {
      final replace = await showReplaceCartDialog(
        context,
        currentStoreName: CartService.cartStoreName ?? 'otra tienda',
      );
      if (!replace) return;
      CartService.clear();
      // clear() wipes the browsing context, so re-establish it for this store.
      CartService.setStore(
        id: storeId,
        name: storeName,
        tone: storeTone,
        time: deliveryTime ?? '',
        fee: deliveryFee,
      );
    }
    if (!mounted) return;

    final sizeName = product.sizes.isNotEmpty && _sizeIdx >= 0
        ? ' (${product.sizes[_sizeIdx].name})'
        : '';
    final selectedExtras = product.extras
        .asMap()
        .entries
        .where((e) => e.key < _extras.length && _extras[e.key])
        .map((e) => e.value.name)
        .join(', ');
    final selectedCutlery = product.cutlery
        .asMap()
        .entries
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
    CartService.addOrIncrement(
      CartEntry(
        productId: product.id,
        name: '${product.name}$sizeName',
        note: noteParts.isEmpty ? null : noteParts.join(' · '),
        tone: product.tone,
        imageUrl: product.imageUrl,
        unitPrice: _computePrice(product) / _qty,
        qty: _qty,
        storeId: storeId,
        storeName: storeName,
        storeTone: storeTone,
        deliveryTime: deliveryTime,
        deliveryFee: deliveryFee,
      ),
    );
    // Non-blocking feedback — keep the user on the screen so they can keep
    // browsing and adding more products. Navigation to the cart is explicit
    // (the floating "Ver carrito" bar on the store screen).
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Agregado al carrito · ${product.name}'),
        duration: Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Future<void> _handleAdd(ProductModel product) async {
    if (_adding) return;
    if (!product.isAvailable) {
      _showAddError('Este producto ya no está disponible.');
      return;
    }
    if (product.sizes.isNotEmpty && _sizeIdx < 0) {
      _showAddError('Selecciona un tamaño para continuar.');
      return;
    }
    final unitPrice = _computePrice(product) / _qty;
    if (unitPrice <= 0) {
      _showAddError('El producto no tiene un precio válido.');
      return;
    }
    setState(() => _adding = true);
    try {
      final store = await DbService.getStore(product.storeId);
      if (store == null) {
        _showAddError('No pudimos verificar el comercio.');
        return;
      }
      if (!store.isOpen) {
        _showAddError('Este comercio está cerrado.');
        return;
      }
      await _addToCart(product);
    } catch (_) {
      _showAddError('No pudimos agregar el producto. Inténtalo nuevamente.');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _showAddError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
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
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    AppSkeleton(height: 320, radius: 0),
                    SizedBox(height: 20),
                    AppSkeleton(height: 28, width: 220),
                    SizedBox(height: 12),
                    AppSkeleton(height: 70),
                  ],
                ),
              ),
            ),
          );
        }
        final product = snap.data;
        if (snap.hasError || product == null) {
          return Scaffold(
            body: AppStateView(
              icon: Icons.fastfood_outlined,
              title: 'No pudimos abrir este producto',
              message: 'Puede que ya no esté disponible o falte conexión.',
              actionLabel: 'Reintentar',
              onAction: _storeId == null || _productId == null
                  ? null
                  : () => setState(
                      () => _future = DbService.getProduct(
                        _storeId!,
                        _productId!,
                      ),
                    ),
            ),
          );
        }
        if (_extras.length != product.extras.length) {
          _extras = List.filled(product.extras.length, false);
        }
        if (_cutlery.length != product.cutlery.length) {
          _cutlery = List.filled(product.cutlery.length, false);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          bottomNavigationBar: _buildBottomBar(product),
          body: Column(
            children: [
              Stack(
                children: [
                  ImgPlaceholder(
                    label: 'FOTO DE PRODUCTO · GRANDE',
                    height: 280,
                    radius: 0,
                    tone: product.tone,
                    assetPath: assetForKey(product.id),
                    imageUrl: product.imageUrl,
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    child: _OverlayBtn(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.chevron_left, size: 22),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (CartService.storeName != null)
                        Text(
                          CartService.storeName!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.06,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.48,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      if (product.sizes.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tamaño',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Obligatorio · 1',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...product.sizes.asMap().entries.map((e) {
                          final sel = e.key == _sizeIdx;
                          return GestureDetector(
                            onTap: () => setState(() => _sizeIdx = e.key),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 8),
                              height: 48,
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                  width: 1.5,
                                ),
                                color: sel
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surface,
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
                                            : Theme.of(
                                                context,
                                              ).colorScheme.outlineVariant,
                                        width: 2,
                                      ),
                                    ),
                                    child: sel
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      e.value.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'S/ ${e.value.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      if (product.extras.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Extras',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Opcional',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...product.extras.asMap().entries.map((e) {
                          final sel = e.key < _extras.length && _extras[e.key];
                          return GestureDetector(
                            onTap: () => setState(
                              () => _extras[e.key] = !_extras[e.key],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.outlineVariant,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: sel
                                        ? Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      e.value.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    e.value.price == 0
                                        ? 'Gratis'
                                        : '+${e.value.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      if (product.cutlery.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cubiertos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Opcional',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...product.cutlery.asMap().entries.map((e) {
                          final sel =
                              e.key < _cutlery.length && _cutlery[e.key];
                          return GestureDetector(
                            onTap: () => setState(
                              () => _cutlery[e.key] = !_cutlery[e.key],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.outlineVariant,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: sel
                                        ? Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      e.value.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    e.value.price == 0
                                        ? 'Gratis'
                                        : '+${e.value.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
        );
      },
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Disminuir cantidad',
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                    icon: Icon(Icons.remove_rounded, size: 18),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$_qty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aumentar cantidad',
                    onPressed: () => setState(() => _qty++),
                    icon: Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label:
                    'Agregar · S/ ${_computePrice(product).toStringAsFixed(2)}',
                onTap: () => _handleAdd(product),
                isLoading: _adding,
              ),
            ),
          ],
        ),
      ),
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
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
