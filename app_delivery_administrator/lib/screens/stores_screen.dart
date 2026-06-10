import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/store_model.dart';
import '../routes.dart';
import '../services/store_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'Todas'; // 'Todas' = sin filtro
  String _estado = 'Todos'; // Todos | Activos | Pausados

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StoreModel> _applyFilters(List<StoreModel> all) {
    final q = _query.trim().toLowerCase();
    return all.where((s) {
      if (q.isNotEmpty &&
          !s.name.toLowerCase().contains(q) &&
          !s.category.toLowerCase().contains(q)) {
        return false;
      }
      if (_category != 'Todas' && s.category != _category) return false;
      if (_estado == 'Activos' && !s.activo) return false;
      if (_estado == 'Pausados' && s.activo) return false;
      return true;
    }).toList();
  }

  Future<void> _openAddStore() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const AddStoreDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'comercios',
      title: 'Comercios',
      actions: [
        const AdminButton(
            label: 'Exportar',
            icon: Icons.file_download_outlined,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(
            label: 'Agregar comercio',
            icon: Icons.add,
            size: AdminBtnSize.sm,
            onPressed: _openAddStore),
      ],
      child: StreamBuilder<List<StoreModel>>(
        stream: StoreService.getStoresStream(),
        builder: (context, snap) {
          final stores = snap.data ?? const <StoreModel>[];
          final active = stores.where((s) => s.activo).length;
          final paused = stores.where((s) => !s.activo).length;
          final pending = stores.where((s) => s.pendingApproval).length;
          final categories = <String>{
            'Todas',
            for (final s in stores)
              if (s.category.isNotEmpty) s.category,
          }.toList();
          final filtered = _applyFilters(stores);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Metrics(items: [
                ('Total comercios', '${stores.length}', null),
                ('Activos', '$active', AdminColors.green),
                ('Pausados', '$paused', AdminColors.amber),
                ('Pendientes alta', '$pending', AdminColors.primary),
              ]),
              const SizedBox(height: 16),
              _Filters(
                searchCtrl: _searchCtrl,
                onSearch: (v) => setState(() => _query = v),
                category: _category,
                categories: categories,
                onCategory: (v) => setState(() => _category = v),
                estado: _estado,
                onEstado: (v) => setState(() => _estado = v),
              ),
              _StoresTable(stores: filtered, loading: !snap.hasData),
            ],
          );
        },
      ),
    );
  }
}

/// Metric cards — uses a Row/Expanded layout (content-sized height) instead of
/// a fixed-aspect-ratio GridView, which was the source of the bottom overflow.
class _Metrics extends StatelessWidget {
  final List<(String, String, Color?)> items;
  const _Metrics({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1100 ? 4 : 2;
      return Column(
        children: [
          for (var i = 0; i < items.length; i += cols) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = i; j < i + cols; j++) ...[
                  if (j > i) const SizedBox(width: 16),
                  Expanded(
                    child: j < items.length
                        ? _MetricCard(item: items[j])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    });
  }
}

class _MetricCard extends StatelessWidget {
  final (String, String, Color?) item;
  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.$1,
              style: const TextStyle(
                  fontSize: 12,
                  color: AdminColors.textMuted,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(item.$2,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: item.$3 ?? AdminColors.text)),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final String category;
  final List<String> categories;
  final ValueChanged<String> onCategory;
  final String estado;
  final ValueChanged<String> onEstado;

  const _Filters({
    required this.searchCtrl,
    required this.onSearch,
    required this.category,
    required this.categories,
    required this.onCategory,
    required this.estado,
    required this.onEstado,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onSearch,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Buscar comercio por nombre o categoría…',
                    prefixIcon: const Icon(Icons.search,
                        size: 16, color: AdminColors.textMuted),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 34, minHeight: 34),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AdminColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AdminColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AdminColors.text, width: 1.4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _FilterDropdown(
              label: 'Categoría',
              value: category,
              options: categories,
              onSelected: onCategory,
              width: 150,
            ),
            const SizedBox(width: 10),
            _FilterDropdown(
              label: 'Estado',
              value: estado,
              options: const ['Todos', 'Activos', 'Pausados'],
              onSelected: onEstado,
              width: 130,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordered dropdown styled like the design's filter chips, backed by a real
/// PopupMenuButton.
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final double width;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = value == options.first;
    return PopupMenuButton<String>(
      onSelected: onSelected,
      tooltip: label,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => options
          .map((o) => PopupMenuItem<String>(
                value: o,
                height: 38,
                child: Text(o, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      child: Container(
        width: width,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AdminColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isDefault ? label : value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDefault ? AdminColors.textMuted : AdminColors.text,
                ),
              ),
            ),
            const Icon(Icons.expand_more, size: 14, color: AdminColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StoresTable extends StatelessWidget {
  final List<StoreModel> stores;
  final bool loading;
  const _StoresTable({required this.stores, required this.loading});

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AdminColors.bg,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                _Th('Comercio', flex: 4),
                _Th('Categoría', flex: 3),
                _Th('Estado', flex: 2),
                _Th('Ventas mes (S/)', flex: 2, align: TextAlign.right),
                _Th('Comisión', flex: 2, align: TextAlign.right),
                _Th('Rating', flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (stores.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No hay comercios que coincidan con el filtro.',
                  style:
                      TextStyle(fontSize: 13, color: AdminColors.textMuted),
                ),
              ),
            )
          else
            for (int i = 0; i < stores.length; i++)
              _StoreRow(store: stores[i], index: i),
        ],
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  final StoreModel store;
  final int index;
  const _StoreRow({required this.store, required this.index});

  @override
  Widget build(BuildContext context) {
    const tints = [
      Color(0xFFFFE8DB),
      Color(0xFFDFF0E7),
      Color(0xFFE0E7FA),
      Color(0xFFEFDEF5),
      Color(0xFFFEF3C7),
    ];
    final tint = tints[index % tints.length];
    final isActive = store.activo;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AdminRoutes.storeDetail,
          arguments: store),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: index == 0
              ? null
              : const Border(
                  top: BorderSide(color: AdminColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      store.name.isEmpty ? '?' : store.name[0],
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AdminColors.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name,
                            maxLines: 1,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text(
                            store.district ??
                                (store.address.isEmpty ? '—' : store.address),
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AdminColors.textMuted),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                store.category.isEmpty ? '—' : store.category,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 13, color: AdminColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminBadge(
                  isActive ? 'Activo' : 'Pausado',
                  tone: isActive ? 'green' : 'amber',
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                store.monthSales == null
                    ? '—'
                    : store.monthSales!.toStringAsFixed(0),
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${(store.commissionPct ?? 18).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.star,
                      size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(store.rating.toStringAsFixed(1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _Th(this.label,
      {required this.flex, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
            fontSize: 11,
            color: AdminColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6),
      ),
    );
  }
}

/// ─── Add store dialog ──────────────────────────────────────────────
class AddStoreDialog extends StatefulWidget {
  const AddStoreDialog({super.key});

  @override
  State<AddStoreDialog> createState() => _AddStoreDialogState();
}

class _AddStoreDialogState extends State<AddStoreDialog> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _ruc = TextEditingController();
  final _contacto = TextEditingController();
  final _commission = TextEditingController(text: '18');
  bool _isOpen = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _ruc.dispose();
    _contacto.dispose();
    _commission.dispose();
    super.dispose();
  }

  String _slug(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');

  Future<void> _save() async {
    final name = _name.text.trim();
    final category = _category.text.trim();
    if (name.isEmpty || category.isEmpty) {
      setState(() => _error = 'Nombre y categoría son obligatorios.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final store = StoreModel(
      id: '',
      name: name,
      category: category,
      categorySlug: _slug(category),
      rating: 0,
      reviewCount: 0,
      deliveryTime: '20-30 min',
      deliveryFee: 0,
      isOpen: _isOpen,
      address: _address.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      ruc: _ruc.text.trim().isEmpty ? null : _ruc.text.trim(),
      contacto:
          _contacto.text.trim().isEmpty ? null : _contacto.text.trim(),
      commissionPct: double.tryParse(_commission.text.trim()) ?? 18,
      activo: true,
      pendingApproval: false,
    );
    try {
      await StoreService.createStore(store);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comercio "$name" creado.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo crear el comercio: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Agregar comercio',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DialogField(label: 'Nombre *', controller: _name),
              const SizedBox(height: 12),
              _DialogField(label: 'Categoría *', controller: _category),
              const SizedBox(height: 12),
              _DialogField(label: 'Dirección', controller: _address),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DialogField(
                        label: 'Teléfono',
                        controller: _phone,
                        keyboardType: TextInputType.phone),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogField(
                        label: 'Email',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DialogField(label: 'RUC', controller: _ruc),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogField(
                        label: 'Comisión (%)',
                        controller: _commission,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DialogField(label: 'Contacto', controller: _contacto),
              const SizedBox(height: 14),
              Row(
                children: [
                  Switch(
                    value: _isOpen,
                    activeThumbColor: AdminColors.primary,
                    onChanged: (v) => setState(() => _isOpen = v),
                  ),
                  const SizedBox(width: 4),
                  Text(_isOpen ? 'Abierto al crear' : 'Cerrado al crear',
                      style: const TextStyle(
                          fontSize: 13, color: AdminColors.textMuted)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(
                        fontSize: 12.5, color: AdminColors.red)),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminButton(
                      label: 'Cancelar',
                      variant: AdminBtnVariant.secondary,
                      size: AdminBtnSize.md,
                      onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  AdminButton(
                      label: 'Crear comercio',
                      size: AdminBtnSize.md,
                      loading: _saving,
                      onPressed: _save),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _DialogField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return AdminTextField(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
    );
  }
}
