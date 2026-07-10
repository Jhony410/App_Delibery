import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../services/db_service.dart';
import '../services/cart_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _tabIdx = 0;
  String? _storeId;
  Future<(StoreModel?, List<ProductModel>)> _future =
      Future.value((null, <ProductModel>[]));


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
        fee: store.deliveryFee,
      );
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
            body: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (!snap.hasData || snap.data!.$1 == null) {
          return const Scaffold(
            body: Center(child: Text('Tienda no encontrada')),
          );
        }
        final store = snap.data!.$1!;
        final allProducts = snap.data!.$2;
        final tabs = allProducts
            .map((p) => p.category)
            .toSet()
            .toList();
        final filtered = _tabIdx < tabs.length
            ? allProducts
                .where((p) => p.category == tabs[_tabIdx])
                .toList()
            : allProducts;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: 120 + MediaQuery.of(context).padding.bottom),
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
                          child: const Icon(Icons.chevron_left, size: 22),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: 20,
                        child: const Row(
                          children: [
                            _OverlayBtn(
                                child: Icon(Icons.favorite_border, size: 20)),
                            SizedBox(width: 8),
                            _OverlayBtn(
                                child: Icon(Icons.search, size: 20)),
                          ],
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
                          color: Colors.white,
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
                            Text(store.name,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.44)),
                            const SizedBox(height: 3),
                            Text(store.category,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textMuted)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _InfoChip(
                                  icon: Icons.star_rounded,
                                  iconColor: AppColors.star,
                                  label: store.rating.toStringAsFixed(1),
                                  sub: '(${store.reviewCount ~/ 1000}.${(store.reviewCount % 1000) ~/ 100}k)',
                                ),
                                const SizedBox(width: 16),
                                _InfoChip(
                                  icon: Icons.access_time,
                                  label: '${store.deliveryTime} min',
                                ),
                                const SizedBox(width: 16),
                                _InfoChip(
                                  icon: Icons.directions_bike_outlined,
                                  label:
                                      'S/ ${store.deliveryFee.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom:
                                    BorderSide(color: AppColors.border)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: tabs.asMap().entries.map((e) {
                                final selected = e.key == _tabIdx;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _tabIdx = e.key),
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
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        ...filtered.map((product) => _MenuItemRow(
                              item: product,
                              storeId: store.id,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/product',
                                arguments: {
                                  'storeId': store.id,
                                  'productId': product.id,
                                },
                              ).then((_) => setState(() {})),
                            )),
                      ],
                    ),
                  ),
                ],
                ),
              ),
              if (CartService.itemCount > 0)
                Positioned(
                  bottom: 28 + MediaQuery.of(context).padding.bottom,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/cart')
                            .then((_) => setState(() {})),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.appText,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${CartService.itemCount}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('Ver carrito',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Text(
                            'S/ ${CartService.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? sub;
  const _InfoChip(
      {required this.icon,
      this.iconColor = AppColors.textMuted,
      required this.label,
      this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        if (sub != null) ...[
          const SizedBox(width: 3),
          Text(sub!,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final ProductModel item;
  final String storeId;
  final VoidCallback onTap;
  const _MenuItemRow(
      {required this.item, required this.storeId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                        child: Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      if (item.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.badge!,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.04)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item.description,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.35)),
                  const SizedBox(height: 6),
                  Text('S/ ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
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
                    imageUrl: item.imageUrl),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: AppColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add,
                        size: 18, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
