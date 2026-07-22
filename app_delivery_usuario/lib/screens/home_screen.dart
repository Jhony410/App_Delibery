import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/store_model.dart';
import '../models/address_model.dart';
import '../models/favorite_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
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

  static const _categories = [
    ('Comida', Icons.restaurant, Color(0xFFFF6B35), Color(0xFFFFE8DB), 'comida'),
    ('Farmacia', Icons.medication_outlined, Color(0xFF06A77D), Color(0xFFDFF0E7), 'farmacia'),
    ('Market', Icons.shopping_cart_outlined, Color(0xFF4A6FE3), Color(0xFFE0E7FA), 'market'),
    ('Licores', Icons.liquor_outlined, Color(0xFF8B4B9E), Color(0xFFEFDEF5), 'licores'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _storesFuture = DbService.getStores();
    final uid = AuthService.currentUid;
    _addressFuture =
        uid != null ? DbService.getDefaultAddress(uid) : Future.value(null);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _storesFuture;
  }

  // Abre la gestión de direcciones (modo manage) y refresca la dirección del
  // header al volver, para reflejar cambios en la predeterminada.
  Future<void> _openAddress() async {
    await Navigator.pushNamed(context, '/addresses',
        arguments: AddressListMode.manage);
    if (!mounted) return;
    final uid = AuthService.currentUid;
    setState(() {
      _addressFuture =
          uid != null ? DbService.getDefaultAddress(uid) : Future.value(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.bg,
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
              _buildCategories(context),
              _buildPromoBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openAddress,
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 22, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ENVIAR A',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSubtle,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.04)),
                        Row(
                          children: [
                            Flexible(
                              child: FutureBuilder<AddressModel?>(
                                future: _addressFuture,
                                builder: (context, snap) {
                                  final addr = snap.data;
                                  final label = addr?.street ??
                                      (snap.connectionState ==
                                              ConnectionState.waiting
                                          ? '...'
                                          : 'Agregar dirección');
                                  return Text(label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700));
                                },
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBell(context),
        ],
      ),
    );
  }

  Widget _buildBell(BuildContext context) {
    final uid = AuthService.currentUid;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/notifications'),
      child: Stack(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_none, size: 20),
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
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => MainShellScope.of(context)?.openSearch(null),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 20, color: AppColors.textMuted),
              SizedBox(width: 10),
              Text('Busca comida, tiendas, productos…',
                  style: TextStyle(fontSize: 15, color: AppColors.textSubtle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _categories.map((c) {
          return GestureDetector(
            onTap: () => MainShellScope.of(context)?.openSearch(c.$5),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: c.$4,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(c.$2, size: 30, color: c.$3),
                ),
                const SizedBox(height: 8),
                Text(c.$1,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromoBanner() {
    // Single promotional banner. There is no promos collection in Firestore, so
    // the previous multi-dot pager (which pointed at nothing) was removed.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFFFF8F5B)],
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRIMER PEDIDO',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.08)),
                  const SizedBox(height: 4),
                  const Text('S/ 15 off\nen tu primer pedido',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.78,
                          height: 1.05)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Código DELI15',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreList() {
    return FutureBuilder<List<StoreModel>>(
      future: _storesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No hay tiendas disponibles',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }
        final stores = snap.data!;
        final uid = AuthService.currentUid;
        return StreamBuilder<List<FavoriteModel>>(
          stream: uid != null
              ? DbService.streamUserFavorites(uid)
              : const Stream.empty(),
          builder: (context, favSnap) {
            final favIds =
                (favSnap.data ?? []).map((f) => f.storeId).toSet();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: stores
                    .map((store) =>
                        _storeCard(context, store, favIds.contains(store.id)))
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _storeCard(BuildContext context, StoreModel store, bool isFav) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/store', arguments: store.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ImgPlaceholder(
                  label: store.name.split(' ')[0],
                  height: 84,
                  width: 96,
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
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(store.promo!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15)),
                    const SizedBox(height: 2),
                    Text(store.category,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppColors.star),
                        const SizedBox(width: 3),
                        Text(store.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Text('·',
                            style: TextStyle(color: AppColors.border)),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${store.deliveryTime} min',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleFavorite(store, isFav),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFav ? AppColors.primary : AppColors.textSubtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(StoreModel store, bool isFav) async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    try {
      final nowFav =
          await DbService.toggleFavorite(uid, store.id, store.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(nowFav
              ? '${store.name} agregado a favoritos'
              : '${store.name} quitado de favoritos'),
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo actualizar favoritos'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }
}
