import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_images.dart';
import '../models/store_model.dart';
import '../services/db_service.dart';
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
    setState(() => _loading = true);
    try {
      final stores = await DbService.getStores();
      if (mounted) setState(() { _all = stores; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _all = []; _loading = false; });
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
      backgroundColor: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 19, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Busca tiendas o productos…',
                  hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_ctrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _ctrl.clear();
                  setState(() => _query = '');
                },
                child: const Icon(Icons.close,
                    size: 18, color: AppColors.textMuted),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _categories[i];
          final sel = c.$2 == _categorySlug;
          return GestureDetector(
            onTap: () => setState(() => _categorySlug = c.$2),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? AppColors.appText : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: sel ? Colors.transparent : AppColors.border,
                ),
              ),
              child: Text(c.$1,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textMuted)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filtro: ${_categoryLabel!}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _categorySlug = null),
                  child: const Icon(Icons.close,
                      size: 15, color: AppColors.primary),
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
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final results = _filtered;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadStores,
      child: results.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Text(
                    _query.trim().isEmpty
                        ? 'Sin resultados'
                        : 'Sin resultados para "${_query.trim()}"',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text('COMERCIOS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.06)),
                const SizedBox(height: 10),
                ...results.map(_storeTile),
              ],
            ),
    );
  }

  Widget _storeTile(StoreModel store) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/store', arguments: store.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
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
                  Text(store.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(store.category,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 11, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(store.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(' · ${store.deliveryTime} min',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
