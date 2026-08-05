import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../services/db_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../cart_checkout_sheet.dart';
import '../delivery_config.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _tabIdx = 0;
  String? _storeId;
  Future<(StoreModel?, List<ProductModel>)> _future = Future.value((
    null,
    <ProductModel>[],
  ));
  bool _favorite = false;
  bool _favoriteBusy = false;
  final Set<String> _addingProducts = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id != null && id != _storeId) {
      _storeId = id;
      _future = _load(id);
    }
  }

  Future<(StoreModel?, List<ProductModel>)> _load(String id) async {
    final store = await DbService.getStore(id);
    final products = await DbService.getStoreProducts(id);
    if (store != null) {
      CartService.setStore(
        id: store.id,
        name: store.name,
        tone: store.tone,
        time: store.deliveryTime,
        fee: DeliveryConfig.fixedFee,
      );
      final uid = AuthService.currentUid;
      if (uid != null) {
        try {
          _favorite = await DbService.isFavorite(uid, store.id);
        } catch (_) {
          _favorite = false;
        }
      }
    }
    return (store, products);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(StoreModel?, List<ProductModel>)>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    AppSkeleton(height: 220, radius: 0),
                    SizedBox(height: 20),
                    AppSkeleton(height: 130),
                    SizedBox(height: 12),
                    AppSkeleton(height: 86),
                  ],
                ),
              ),
            ),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.$1 == null) {
          return Scaffold(
            body: AppStateView(
              icon: Icons.store_mall_directory_outlined,
              title: 'No pudimos abrir este comercio',
              message: 'Puede que ya no esté disponible o falte conexión.',
              actionLabel: 'Reintentar',
              onAction: _storeId == null
                  ? null
                  : () => setState(() => _future = _load(_storeId!)),
            ),
          );
        }
        final store = snap.data!.$1!;
        final allProducts = snap.data!.$2;
        final tabs = allProducts.map((p) => p.category).toSet().toList();
        final filtered = _tabIdx < tabs.length
            ? allProducts.where((p) => p.category == tabs[_tabIdx]).toList()
            : allProducts;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          bottomNavigationBar: CartFloatingBar(
            onTap: () => showCartCheckoutSheet(context),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Stack(
                  children: [
                    ImgPlaceholder(
                      label: 'COVER · ${store.name.toUpperCase()}',
                      height: 220,
                      radius: 0,
                      tone: store.tone,
                      assetPath: assetForKey(store.id),
                      imageUrl: store.imagenUrl,
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 20,
                      child: _OverlayBtn(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.chevron_left, size: 22),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      right: 20,
                      child: _OverlayBtn(
                        tooltip: _favorite
                            ? 'Quitar de favoritos'
                            : 'Agregar a favoritos',
                        onTap: _favoriteBusy
                            ? null
                            : () => _toggleFavorite(store),
                        child: Icon(
                          _favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: _favorite
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.44,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            store.category,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.star_rounded,
                                iconColor: AppColors.star,
                                label: store.rating.toStringAsFixed(1),
                                sub:
                                    '(${store.reviewCount ~/ 1000}.${(store.reviewCount % 1000) ~/ 100}k)',
                              ),
                              const SizedBox(width: 16),
                              _InfoChip(
                                icon: Icons.access_time,
                                label: formatDeliveryTime(store.deliveryTime),
                              ),
                              const SizedBox(width: 16),
                              _InfoChip(
                                icon: Icons.directions_bike_outlined,
                                label: DeliveryConfig.formattedFee,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -28),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: tabs.asMap().entries.map((e) {
                              final selected = e.key == _tabIdx;
                              return GestureDetector(
                                onTap: () => setState(() => _tabIdx = e.key),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 20),
                                  padding: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: selected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? AppColors.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: AppStateView(
                            icon: Icons.restaurant_menu_rounded,
                            title: 'No hay productos disponibles',
                            message: 'Este comercio aún no publicó productos.',
                          ),
                        )
                      else
                        ...filtered.map(
                          (product) => _MenuItemRow(
                            item: product,
                            busy: _addingProducts.contains(product.id),
                            onTap: () => _openOrAddProduct(store, product),
                            onAdd: () => _openOrAddProduct(store, product),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(StoreModel store) async {
    final uid = AuthService.currentUid;
    if (uid == null || _favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    try {
      final value = await DbService.toggleFavorite(uid, store.id, store.name);
      if (!mounted) return;
      setState(() => _favorite = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '${store.name} agregado a favoritos'
                : '${store.name} quitado de favoritos',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar favoritos'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _openOrAddProduct(StoreModel store, ProductModel product) async {
    if (_addingProducts.contains(product.id)) return;
    if (product.requiresCustomization) {
      await Navigator.pushNamed(
        context,
        '/product',
        arguments: {'storeId': store.id, 'productId': product.id},
      );
      if (mounted) setState(() {});
      return;
    }

    setState(() => _addingProducts.add(product.id));
    try {
      if (!product.isAvailable) {
        _showCartMessage('Este producto ya no está disponible.', error: true);
        return;
      }
      if (!store.isOpen) {
        _showCartMessage('Este comercio está cerrado.', error: true);
        return;
      }
      if (product.price <= 0) {
        _showCartMessage('El producto no tiene un precio válido.', error: true);
        return;
      }

      if (!CartService.canAddFromStore(store.id)) {
        final replace = await showReplaceCartDialog(
          context,
          currentStoreName: CartService.cartStoreName ?? 'otro comercio',
        );
        if (!replace) return;
        CartService.clear();
        CartService.setStore(
          id: store.id,
          name: store.name,
          tone: store.tone,
          time: store.deliveryTime,
          fee: DeliveryConfig.fixedFee,
        );
      }
      if (!mounted) return;

      CartService.addOrIncrement(
        CartEntry(
          productId: product.id,
          name: product.name,
          tone: product.tone,
          imageUrl: product.imageUrl,
          unitPrice: product.price,
          storeId: store.id,
          storeName: store.name,
          storeTone: store.tone,
          deliveryTime: store.deliveryTime,
          deliveryFee: DeliveryConfig.fixedFee,
        ),
      );
      _showCartMessage('Agregado al carrito · ${product.name}');
    } finally {
      if (mounted) setState(() => _addingProducts.remove(product.id));
    }
  }

  void _showCartMessage(String message, {bool error = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: 1300),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? AppColors.danger
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  const _OverlayBtn({required this.child, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(width: 40, height: 40, child: Center(child: child)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? sub;
  const _InfoChip({
    required this.icon,
    this.iconColor,
    required this.label,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        if (sub != null) ...[
          SizedBox(width: 3),
          Text(
            sub!,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final ProductModel item;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool busy;
  const _MenuItemRow({
    required this.item,
    required this.onTap,
    required this.onAdd,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.badge != null) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.04,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'S/ ${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ImgPlaceholder(
                    label: 'FOTO',
                    height: 80,
                    width: 96,
                    tone: item.tone,
                    radius: 12,
                    assetPath: assetForKey(item.id),
                    imageUrl: item.imageUrl,
                  ),
                  Positioned(
                    bottom: -8,
                    right: -8,
                    child: Tooltip(
                      message: item.requiresCustomization
                          ? 'Elegir opciones'
                          : 'Agregar al carrito',
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: busy ? null : onAdd,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: busy
                                ? Padding(
                                    padding: EdgeInsets.all(9),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    item.requiresCustomization
                                        ? Icons.tune_rounded
                                        : Icons.add_rounded,
                                    size: 19,
                                    color: AppColors.primary,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
