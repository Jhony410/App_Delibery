import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/store_model.dart';
import '../models/address_model.dart';
import '../models/favorite_model.dart';
import '../models/user_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../cart_checkout_sheet.dart';
import '../delivery_config.dart';
import 'main_shell.dart';
import 'addresses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<StoreModel>> _storesFuture;
  late Future<AddressModel?> _addressFuture;
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _storesFuture = DbService.getStores();
    final uid = AuthService.currentUid;
    _userFuture = uid != null ? DbService.getUser(uid) : Future.value(null);
    _addressFuture = uid != null
        ? DbService.getDefaultAddress(uid)
        : Future.value(null);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _storesFuture;
  }

  // Abre la gestión de direcciones (modo manage) y refresca la dirección del
  // header al volver, para reflejar cambios en la predeterminada.
  Future<void> _openAddress() async {
    await Navigator.pushNamed(
      context,
      '/addresses',
      arguments: AddressListMode.manage,
    );
    if (!mounted) return;
    final uid = AuthService.currentUid;
    setState(() {
      _addressFuture = uid != null
          ? DbService.getDefaultAddress(uid)
          : Future.value(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: top + 12),
              _buildHeader(context),
              _buildSearchBar(context),
              _buildDeliveryNotice(),
              _buildPromoBanner(),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SectionTitle(title: '¿Qué estás buscando?'),
              ),
              _buildCategories(context),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: SectionTitle(title: 'Comercios destacados'),
              ),
              _buildStoreLogoStrip(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: SectionTitle(
                  title: 'Cerca de ti',
                  action: 'Ver todo',
                  onAction: () => MainShellScope.of(context)?.openSearch(null),
                ),
              ),
              _buildStoreList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<UserModel?>(
                  future: _userFuture,
                  builder: (context, snap) {
                    final firstName = snap.data?.name.trim().split(' ').first;
                    return Text(
                      firstName == null || firstName.isEmpty
                          ? 'Hola'
                          : 'Hola, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.pageTitle,
                    );
                  },
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: _openAddress,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: FutureBuilder<AddressModel?>(
                            future: _addressFuture,
                            builder: (context, snap) {
                              final addr = snap.data;
                              final label =
                                  addr?.street ??
                                  (snap.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Cargando ubicación'
                                      : 'Agregar dirección de entrega');
                              return Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            },
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildBell(context),
          const SizedBox(width: 8),
          _buildCartButton(context),
        ],
      ),
    );
  }

  Widget _buildBell(BuildContext context) {
    final uid = AuthService.currentUid;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.pushNamed(context, '/notifications'),
        child: Stack(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_none, size: 20),
            ),
            if (uid != null)
              StreamBuilder<int>(
                stream: DbService.countUnreadNotifications(uid),
                builder: (context, snap) {
                  final unread = snap.data ?? 0;
                  if (unread == 0) return const SizedBox.shrink();
                  return Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CartService.revision,
      builder: (context, _, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => showCartCheckoutSheet(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.shopping_bag_outlined, size: 20),
              ),
            ),
          ),
          if (CartService.itemCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: CartCountBadge(count: CartService.itemCount),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => MainShellScope.of(context)?.openSearch(null),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Busca comercios y categorías',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return HomeCategoryGrid(
      onSelected: (slug) => MainShellScope.of(context)?.openSearch(slug),
    );
  }

  Widget _buildDeliveryNotice() {
    return const FixedDeliveryNotice();
  }

  Widget _buildPromoBanner() {
    // Single promotional banner. There is no promos collection in Firestore, so
    // the previous multi-dot pager (which pointed at nothing) was removed.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: () => MainShellScope.of(context)?.openSearch(null),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            constraints: const BoxConstraints(minHeight: 146),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.secondary],
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DELIVERY EN PUNO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.08,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Tus favoritos,\nmás cerca de ti',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Explorar comercios',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 126,
                    height: 112,
                    child: Image.asset(
                      'images/restaurantes sin fondo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.restaurant_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreList() {
    return FutureBuilder<List<StoreModel>>(
      future: _storesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                AppSkeleton(height: 104),
                SizedBox(height: 12),
                AppSkeleton(height: 104),
              ],
            ),
          );
        }
        if (snap.hasError) {
          return AppStateView(
            icon: Icons.cloud_off_rounded,
            title: 'No pudimos cargar los comercios',
            message: 'Revisa tu conexión e inténtalo nuevamente.',
            actionLabel: 'Reintentar',
            onAction: () => setState(_load),
          );
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const AppStateView(
            icon: Icons.storefront_outlined,
            title: 'No hay comercios disponibles',
            message: 'Vuelve a intentarlo dentro de unos minutos.',
          );
        }
        final stores = snap.data!;
        final uid = AuthService.currentUid;
        return StreamBuilder<List<FavoriteModel>>(
          stream: uid != null
              ? DbService.streamUserFavorites(uid)
              : const Stream.empty(),
          builder: (context, favSnap) {
            final favIds = (favSnap.data ?? []).map((f) => f.storeId).toSet();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: stores
                    .map(
                      (store) =>
                          _storeCard(context, store, favIds.contains(store.id)),
                    )
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStoreLogoStrip() {
    return SizedBox(
      height: 94,
      child: FutureBuilder<List<StoreModel>>(
        future: _storesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  AppSkeleton(height: 64, width: 64),
                  SizedBox(width: 12),
                  AppSkeleton(height: 64, width: 64),
                  SizedBox(width: 12),
                  AppSkeleton(height: 64, width: 64),
                  SizedBox(width: 12),
                  AppSkeleton(height: 64, width: 64),
                ],
              ),
            );
          }
          final stores = snap.data ?? const <StoreModel>[];
          if (snap.hasError || stores.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            key: const PageStorageKey('home-store-logos'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: stores.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = stores[index];
              return Semantics(
                button: true,
                label: 'Abrir ${store.name}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/store',
                    arguments: store.id,
                  ),
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            boxShadow: AppShadows.card,
                          ),
                          child: ImgPlaceholder(
                            height: 58,
                            width: 58,
                            radius: 9,
                            tone: store.tone,
                            assetPath: assetForKey(store.id),
                            imageUrl: store.imagenUrl,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _storeCard(BuildContext context, StoreModel store, bool isFav) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () =>
            Navigator.pushNamed(context, '/store', arguments: store.id),
        child: Container(
          margin: EdgeInsets.only(bottom: 14),
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ImgPlaceholder(
                    label: store.name.split(' ')[0],
                    height: 92,
                    width: 104,
                    tone: store.tone,
                    radius: 12,
                    assetPath: assetForKey(store.id),
                    imageUrl: store.imagenUrl,
                  ),
                  if (store.promo != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          store.promo!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        store.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.star,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                store.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 3),
                              Text(
                                formatDeliveryTime(store.deliveryTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Delivery ${DeliveryConfig.formattedFee}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                visualDensity: VisualDensity.compact,
                onPressed: () => _toggleFavorite(store, isFav),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFav
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(StoreModel store, bool isFav) async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    try {
      final nowFav = await DbService.toggleFavorite(uid, store.id, store.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowFav
                  ? '${store.name} agregado a favoritos'
                  : '${store.name} quitado de favoritos',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar favoritos'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class HomeCategoryGrid extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const HomeCategoryGrid({super.key, required this.onSelected});

  static const categories = [
    ('Restaurantes', 'images/restaurantes sin fondo.png', 'comida'),
    ('Farmacia', 'images/farmacia sin fondo.png', 'farmacia'),
    ('Market', 'images/market sin fondo.png', 'market'),
    ('Licores', 'images/licores sin fondo.png', 'licores'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 132,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final lightColor = switch (index) {
            0 => const Color(0xFFE7F4FC),
            1 => const Color(0xFFE5F6EF),
            2 => const Color(0xFFEEF1F8),
            _ => const Color(0xFFFFF4DC),
          };
          return Material(
            color: context.isDark
                ? context.colors.surfaceContainerHigh
                : lightColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(category.$3),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 3,
                    bottom: 34,
                    child: Image.asset(
                      category.$2,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.category_outlined,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 11,
                    child: Text(
                      category.$1,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FixedDeliveryNotice extends StatelessWidget {
  const FixedDeliveryNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.delivery_dining_rounded,
              size: 21,
              color: context.colors.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Delivery a cualquier local por ${DeliveryConfig.formattedFee}',
                style: TextStyle(
                  color: context.colors.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
