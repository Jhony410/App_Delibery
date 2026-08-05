import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/store_model.dart';
import '../services/db_service.dart';
import '../delivery_config.dart';
import 'main_shell.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  // Category filter chips. `null` slug = "Todas" (no filter).
  static const _categories = [
    ('Todas', null),
    ('Comida', 'comida'),
    ('Farmacia', 'farmacia'),
    ('Market', 'market'),
    ('Licores', 'licores'),
  ];

  List<StoreModel> _all = [];
  bool _loading = true;
  bool _loadError = false;
  String _query = '';
  String? _categorySlug;

  ValueNotifier<String?>? _categoryNotifier;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the shell's shared category filter so that opening the
    // Buscar tab from Home applies (or clears) the category selection.
    final scope = MainShellScope.of(context);
    final notifier = scope?.searchCategory;
    if (notifier != null && notifier != _categoryNotifier) {
      _categoryNotifier?.removeListener(_onExternalCategory);
      _categoryNotifier = notifier;
      _categoryNotifier!.addListener(_onExternalCategory);
      // Apply the current value straight away.
      _categorySlug = notifier.value;
    }
  }

  void _onExternalCategory() {
    if (!mounted) return;
    setState(() => _categorySlug = _categoryNotifier?.value);
  }

  @override
  void dispose() {
    _categoryNotifier?.removeListener(_onExternalCategory);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      final stores = await DbService.getStores();
      if (mounted) {
        setState(() {
          _all = stores;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _all = [];
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  List<StoreModel> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((s) {
      if (_categorySlug != null && s.categorySlug != _categorySlug) {
        return false;
      }
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
    }).toList();
  }

  String? get _categoryLabel {
    if (_categorySlug == null) return null;
    for (final c in _categories) {
      if (c.$2 == _categorySlug) return c.$1;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top + 8),
          _buildSearchField(),
          _buildCategoryChips(),
          if (_categoryLabel != null) _buildActiveFilterChip(),
          const SizedBox(height: 4),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 46,
        padding: EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 19,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: false,
                  hintText: 'Busca tiendas o categorías',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_ctrl.text.isNotEmpty)
              IconButton(
                tooltip: 'Limpiar búsqueda',
                constraints: BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
                onPressed: () {
                  _ctrl.clear();
                  setState(() => _query = '');
                },
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _categories[i];
          final sel = c.$2 == _categorySlug;
          return ChoiceChip(
            showCheckmark: false,
            selected: sel,
            onSelected: (_) => setState(() => _categorySlug = c.$2),
            side: BorderSide(
              color: sel
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            label: Text(
              c.$1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: sel
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterChip() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filtro: ${_categoryLabel!}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _categorySlug = null),
                  child: Icon(Icons.close, size: 15, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            AppSkeleton(height: 78),
            SizedBox(height: 10),
            AppSkeleton(height: 78),
            SizedBox(height: 10),
            AppSkeleton(height: 78),
          ],
        ),
      );
    }
    if (_loadError) {
      return AppStateView(
        icon: Icons.wifi_off_rounded,
        title: 'No pudimos buscar comercios',
        message: 'Comprueba tu conexión e inténtalo nuevamente.',
        actionLabel: 'Reintentar',
        onAction: _loadStores,
      );
    }
    final results = _filtered;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadStores,
      child: results.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                AppStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No encontramos resultados',
                  message: _query.trim().isEmpty
                      ? 'Prueba con otra categoría.'
                      : 'Prueba con un nombre o categoría diferente.',
                ),
              ],
            )
          : ListView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              children: [
                Text(
                  'COMERCIOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 10),
                ...results.map(_storeTile),
              ],
            ),
    );
  }

  Widget _storeTile(StoreModel store) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () =>
            Navigator.pushNamed(context, '/store', arguments: store.id),
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              ImgPlaceholder(
                label: store.name.split(' ')[0],
                height: 56,
                width: 56,
                tone: store.tone,
                radius: 10,
                assetPath: assetForKey(store.id),
                imageUrl: store.imagenUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      store.category,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: AppColors.star,
                        ),
                        SizedBox(width: 3),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' · ${formatDeliveryTime(store.deliveryTime)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Delivery ${DeliveryConfig.formattedFee}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
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
