import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import '../models/store_model.dart';
import '../routes.dart';
import '../services/store_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

const _monthAbbr = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

String _fmtDate(DateTime d) =>
    '${d.day} ${_monthAbbr[d.month - 1]} ${d.year}';

/// Re-encodes [input] as a JPEG bounded to [maxWidth] px wide at [quality]
/// (0-100) so uploads to Storage stay small. Only downsizes — images already
/// narrower than [maxWidth] keep their resolution. Returns the original bytes
/// untouched if decoding fails (e.g. an unsupported format), so a bad decode
/// never blocks the upload.
Uint8List _compressToJpeg(Uint8List input,
    {int maxWidth = 900, int quality = 80}) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return input;
  final resized = decoded.width > maxWidth
      ? img.copyResize(decoded, width: maxWidth)
      : decoded;
  return img.encodeJpg(resized, quality: quality);
}

String _money(double v) {
  final neg = v < 0;
  final s = v.abs().toStringAsFixed(0);
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'S/ ${neg ? '-' : ''}$b';
}

const _dayLabels = <String, String>{
  'mon': 'Lunes',
  'tue': 'Martes',
  'wed': 'Miércoles',
  'thu': 'Jueves',
  'fri': 'Viernes',
  'sat': 'Sábado',
  'sun': 'Domingo',
};

class StoreDetailScreen extends StatefulWidget {
  final StoreModel? store;
  const StoreDetailScreen({super.key, this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  static const _tabs = [
    'General', 'Menú', 'Horarios', 'Comisión', 'Ventas', 'Documentos'
  ];

  late StoreModel _store;
  int _tab = 0;

  // General tab controllers
  late final TextEditingController _name;
  late final TextEditingController _ruc;
  late final TextEditingController _category;
  late final TextEditingController _district;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _contacto;
  late final TextEditingController _mapsUrl;

  bool _savingGeneral = false;
  bool _togglingStatus = false;
  bool _uploadingImage = false;
  bool _deleting = false;

  Future<StoreMonthStats>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _store = widget.store ??
        const StoreModel(
          id: '',
          name: '',
          category: '',
          categorySlug: '',
          rating: 0,
          reviewCount: 0,
          deliveryTime: '',
          deliveryFee: 0,
          address: '',
        );
    _name = TextEditingController(text: _store.name);
    _ruc = TextEditingController(text: _store.ruc ?? '');
    _category = TextEditingController(text: _store.category);
    _district = TextEditingController(text: _store.district ?? '');
    _address = TextEditingController(text: _store.address);
    _phone = TextEditingController(text: _store.phone ?? '');
    _email = TextEditingController(text: _store.email ?? '');
    _contacto = TextEditingController(text: _store.contacto ?? '');
    _mapsUrl = TextEditingController(text: _store.mapsUrl ?? '');
    if (_store.id.isNotEmpty) _refreshStats();
  }

  @override
  void dispose() {
    _name.dispose();
    _ruc.dispose();
    _category.dispose();
    _district.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _contacto.dispose();
    _mapsUrl.dispose();
    super.dispose();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture =
          StoreService.monthStats(_store.id, _store.commissionPct ?? 18);
    });
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AdminColors.red : null,
    ));
  }

  Future<void> _saveGeneral() async {
    if (_store.id.isEmpty) return;
    setState(() => _savingGeneral = true);
    final fields = {
      'name': _name.text.trim(),
      'ruc': _ruc.text.trim(),
      'category': _category.text.trim(),
      'district': _district.text.trim(),
      'address': _address.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'contacto': _contacto.text.trim(),
      'mapsUrl': _mapsUrl.text.trim(),
    };
    try {
      await StoreService.updateStore(_store.id, fields);
      setState(() {
        _store = _store.copyWith(
          name: fields['name'],
          ruc: fields['ruc'],
          category: fields['category'],
          district: fields['district'],
          address: fields['address'],
          phone: fields['phone'],
          email: fields['email'],
          contacto: fields['contacto'],
          mapsUrl: fields['mapsUrl'],
        );
        _savingGeneral = false;
      });
      _snack('Cambios guardados.');
    } catch (e) {
      setState(() => _savingGeneral = false);
      _snack('No se pudo guardar: $e', error: true);
    }
  }

  Future<void> _toggleStatus() async {
    if (_store.id.isEmpty) return;
    setState(() => _togglingStatus = true);
    final next = !_store.activo;
    try {
      await StoreService.toggleStoreStatus(_store.id, next);
      setState(() {
        _store = _store.copyWith(activo: next);
        _togglingStatus = false;
      });
      _snack(next ? 'Comercio reactivado.' : 'Comercio pausado.');
    } catch (e) {
      setState(() => _togglingStatus = false);
      _snack('No se pudo cambiar el estado: $e', error: true);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    if (_store.id.isEmpty) return;
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
    } catch (e) {
      _snack('No se pudo abrir el selector de imagen: $e', error: true);
      return;
    }
    if (file == null) return; // user cancelled
    setState(() => _uploadingImage = true);
    try {
      final raw = await file.readAsBytes();
      // Compress client-side (≤900px wide, JPEG q80) to keep Storage small.
      final bytes = _compressToJpeg(raw);
      final url = await StoreService.uploadStoreLogo(
        _store.id,
        bytes,
        contentType: 'image/jpeg',
      );
      await StoreService.updateStore(_store.id, {'imagenUrl': url});
      setState(() {
        _store = _store.copyWith(imagenUrl: url);
        _uploadingImage = false;
      });
      _snack('Foto del local actualizada.');
    } catch (e) {
      setState(() => _uploadingImage = false);
      _snack('No se pudo subir la foto: $e', error: true);
    }
  }

  Future<void> _deleteStore() async {
    if (_store.id.isEmpty) return;
    // Check for associated order history so the dialog can warn the admin.
    int? orderCount;
    try {
      orderCount = await StoreService.countOrdersForStore(_store.id);
    } catch (_) {
      orderCount = null; // couldn't verify — the dialog notes this
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar comercio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '¿Eliminar "${_store.name}"? Esta acción no se puede deshacer.'),
            if (orderCount != null && orderCount > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AdminColors.red.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Este comercio tiene $orderCount pedido(s) asociado(s). '
                  'Eliminarlo puede afectar el historial de esos pedidos, que '
                  'quedarán sin comercio de referencia. Los pedidos y los '
                  'productos NO se eliminan automáticamente.',
                  style: const TextStyle(
                      fontSize: 12.5, color: AdminColors.red),
                ),
              ),
            ] else if (orderCount == null) ...[
              const SizedBox(height: 14),
              const Text(
                'No se pudo verificar si el comercio tiene pedidos asociados.',
                style:
                    TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AdminColors.red),
              child: const Text('Eliminar de todas formas')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await StoreService.deleteStore(_store.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comercio "${_store.name}" eliminado.')),
      );
      Navigator.pushReplacementNamed(context, AdminRoutes.stores);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _snack('No se pudo eliminar el comercio: $e', error: true);
    }
  }

  Future<void> _saveCommission(double pct) async {
    try {
      await StoreService.updateCommission(_store.id, pct);
      setState(() {
        _store = _store.copyWith(
            commissionPct: pct, commissionUpdatedAt: DateTime.now());
      });
      _refreshStats();
      _snack('Comisión actualizada a ${pct.toStringAsFixed(0)}%.');
    } catch (e) {
      _snack('No se pudo actualizar la comisión: $e', error: true);
    }
  }

  Future<void> _saveHorarios(Map<String, dynamic> horarios) async {
    try {
      await StoreService.updateStore(_store.id, {'horarios': horarios});
      setState(() => _store = _store.copyWith(horarios: horarios));
      _snack('Horarios guardados.');
    } catch (e) {
      _snack('No se pudieron guardar los horarios: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store == null) {
      return const AdminShell(
        activeId: 'comercios',
        title: 'Comercio',
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('Comercio no encontrado.'),
          ),
        ),
      );
    }
    final s = _store;
    return AdminShell(
      activeId: 'comercios',
      title: s.name,
      actions: [
        AdminButton(
          label: 'Eliminar',
          icon: Icons.delete_outline,
          variant: AdminBtnVariant.danger,
          size: AdminBtnSize.sm,
          loading: _deleting,
          onPressed: _store.id.isEmpty ? null : _deleteStore,
        ),
        AdminButton(
          label: s.activo ? 'Pausar' : 'Reactivar',
          variant: AdminBtnVariant.secondary,
          size: AdminBtnSize.sm,
          loading: _togglingStatus,
          onPressed: _toggleStatus,
        ),
        AdminButton(
          label: 'Guardar cambios',
          size: AdminBtnSize.sm,
          loading: _savingGeneral,
          onPressed: _tab == 0 ? _saveGeneral : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Breadcrumb(name: s.name, activo: s.activo),
          const SizedBox(height: 20),
          _TabsBar(
            tabs: _tabs,
            index: _tab,
            onTap: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 20),
          _buildTab(),
        ],
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _generalLayout();
      case 1:
        return _MenuTab(storeId: _store.id, onSnack: _snack);
      case 2:
        return _HorariosTab(
            horarios: _store.horarios, onSave: _saveHorarios);
      case 3:
        return _ComisionTab(store: _store, onSave: _saveCommission);
      case 4:
        return _VentasTab(statsFuture: _statsFuture);
      default:
        return const _DocumentosTab();
    }
  }

  Widget _generalLayout() {
    return LayoutBuilder(builder: (context, c) {
      final twoCol = c.maxWidth > 1100;
      final main = _GeneralForm(
        name: _name,
        ruc: _ruc,
        category: _category,
        district: _district,
        address: _address,
        phone: _phone,
        email: _email,
        contacto: _contacto,
        mapsUrl: _mapsUrl,
        saving: _savingGeneral,
        onSave: _saveGeneral,
        activo: _store.activo,
        toggling: _togglingStatus,
        onToggle: _toggleStatus,
        imageUrl: _store.imagenUrl,
        uploadingImage: _uploadingImage,
        onPickImage: _pickAndUploadLogo,
      );
      final side = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CommissionMiniCard(
            pct: _store.commissionPct ?? 18,
            updatedAt: _store.commissionUpdatedAt,
            onEdit: () => setState(() => _tab = 3),
          ),
          const SizedBox(height: 16),
          _MonthSummaryCard(
              statsFuture: _statsFuture, rating: _store.rating),
        ],
      );
      if (!twoCol) {
        return Column(children: [main, const SizedBox(height: 16), side]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: main),
          const SizedBox(width: 20),
          SizedBox(width: 320, child: side),
        ],
      );
    });
  }
}

class _Breadcrumb extends StatelessWidget {
  final String name;
  final bool activo;
  const _Breadcrumb({required this.name, required this.activo});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () =>
              Navigator.pushReplacementNamed(context, AdminRoutes.stores),
          child: const Text('Comercios',
              style: TextStyle(
                  fontSize: 12.5, color: AdminColors.textMuted)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right,
              size: 12, color: AdminColors.textMuted),
        ),
        Flexible(
          child: Text(name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        AdminBadge(activo ? 'Activo' : 'Pausado',
            tone: activo ? 'green' : 'amber'),
      ],
    );
  }
}

class _TabsBar extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onTap;
  const _TabsBar(
      {required this.tabs, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++)
              InkWell(
                onTap: () => onTap(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == index
                            ? AdminColors.text
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: i == index
                          ? AdminColors.text
                          : AdminColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ─── General tab ───────────────────────────────────────────────────
class _GeneralForm extends StatelessWidget {
  final TextEditingController name, ruc, category, district, address, phone,
      email, contacto, mapsUrl;
  final bool saving;
  final VoidCallback onSave;
  final bool activo;
  final bool toggling;
  final VoidCallback onToggle;
  final String? imageUrl;
  final bool uploadingImage;
  final VoidCallback onPickImage;

  const _GeneralForm({
    required this.name,
    required this.ruc,
    required this.category,
    required this.district,
    required this.address,
    required this.phone,
    required this.email,
    required this.contacto,
    required this.mapsUrl,
    required this.saving,
    required this.onSave,
    required this.activo,
    required this.toggling,
    required this.onToggle,
    required this.imageUrl,
    required this.uploadingImage,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final fields = <(String, TextEditingController)>[
      ('Razón social', name),
      ('RUC', ruc),
      ('Categoría', category),
      ('Distrito', district),
      ('Dirección', address),
      ('Teléfono', phone),
      ('Email', email),
      ('Contacto', contacto),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Información general',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              AdminButton(
                label: activo ? 'Pausar' : 'Activar',
                icon: activo ? Icons.pause : Icons.play_arrow,
                variant: AdminBtnVariant.secondary,
                size: AdminBtnSize.sm,
                loading: toggling,
                onPressed: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StorePhoto(
            imageUrl: imageUrl,
            uploading: uploadingImage,
            onPick: onPickImage,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final colW = (c.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: fields
                  .map((f) => SizedBox(
                        width: colW,
                        child: AdminTextField(
                            label: f.$1, controller: f.$2),
                      ))
                  .toList(),
            );
          }),
          const SizedBox(height: 14),
          AdminTextField(
            label: 'Link de Google Maps (ubicación exacta)',
            controller: mapsUrl,
            hint: 'Pega el enlace que Google Maps genera al compartir',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: AdminButton(
              label: 'Guardar cambios',
              icon: Icons.check,
              size: AdminBtnSize.md,
              loading: saving,
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

/// Store photo card: shows the current image (or a placeholder) plus a button to
/// upload/replace it. Upload itself is handled by the parent via [onPick].
class _StorePhoto extends StatelessWidget {
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onPick;
  const _StorePhoto({
    required this.imageUrl,
    required this.uploading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 88,
            height: 88,
            color: AdminColors.grayTint,
            child: hasImage
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: AdminColors.textMuted),
                  )
                : const Icon(Icons.storefront_outlined,
                    size: 28, color: AdminColors.textMuted),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminEyebrow('FOTO DEL LOCAL'),
              const SizedBox(height: 4),
              const Text(
                'Sube una foto real del local. Se guarda en Firebase Storage y '
                'se muestra en la ficha del comercio.',
                style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
              ),
              const SizedBox(height: 10),
              AdminButton(
                label: hasImage ? 'Reemplazar foto' : 'Subir foto',
                icon: Icons.upload_outlined,
                variant: AdminBtnVariant.secondary,
                size: AdminBtnSize.sm,
                loading: uploading,
                onPressed: onPick,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommissionMiniCard extends StatelessWidget {
  final double pct;
  final DateTime? updatedAt;
  final VoidCallback onEdit;
  const _CommissionMiniCard(
      {required this.pct, required this.updatedAt, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminEyebrow('COMISIÓN'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Text('por pedido',
                  style: TextStyle(
                      fontSize: 12, color: AdminColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AdminColors.bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              updatedAt == null
                  ? 'Sin cambios registrados'
                  : 'Vigente desde ${_fmtDate(updatedAt!)}',
              style: const TextStyle(
                  fontSize: 11.5, color: AdminColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          AdminButton(
            label: 'Modificar comisión',
            icon: Icons.edit,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final Future<StoreMonthStats>? statsFuture;
  final double rating;
  const _MonthSummaryCard(
      {required this.statsFuture, required this.rating});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Resumen del mes',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          FutureBuilder<StoreMonthStats>(
            future: statsFuture,
            builder: (context, snap) {
              if (statsFuture == null) {
                return const _SummaryHint('Comercio sin guardar.');
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return const _SummaryHint('No se pudo cargar el resumen.');
              }
              final st = snap.data ?? StoreMonthStats.empty;
              final rows = <(String, String)>[
                ('Pedidos', '${st.orders}'),
                ('Ventas brutas', _money(st.gross)),
                ('Comisión Runa', _money(st.commission)),
                ('A pagar al comercio', _money(st.payout)),
                ('Cancelaciones',
                    '${st.cancellations} (${st.cancelRate.toStringAsFixed(1)}%)'),
                ('Rating prom.', '${rating.toStringAsFixed(1)} ★'),
              ];
              return Column(
                children: [
                  for (final r in rows)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: AdminColors.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.$1,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AdminColors.textMuted)),
                          Text(r.$2,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryHint extends StatelessWidget {
  final String text;
  const _SummaryHint(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12.5, color: AdminColors.textMuted)),
    );
  }
}

/// ─── Menú tab ──────────────────────────────────────────────────────
class _MenuTab extends StatelessWidget {
  final String storeId;
  final void Function(String, {bool error}) onSnack;
  const _MenuTab({required this.storeId, required this.onSnack});

  Future<void> _toggleAvailable(ProductModel p, bool v) async {
    try {
      await StoreService.updateProduct(storeId, p.id, {'isAvailable': v});
    } catch (e) {
      onSnack('No se pudo actualizar: $e', error: true);
    }
  }

  Future<void> _confirmDelete(BuildContext context, ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.name}" del menú? Esta acción no se '
            'puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AdminColors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await StoreService.deleteProduct(storeId, p.id);
      onSnack('Producto eliminado.');
    } catch (e) {
      onSnack('No se pudo eliminar: $e', error: true);
    }
  }

  Future<void> _openProductDialog(BuildContext context,
      {ProductModel? product}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ProductDialog(
        storeId: storeId,
        product: product,
        onSnack: onSnack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (storeId.isEmpty) {
      return const AdminCard(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Guarda el comercio para gestionar su menú.',
              style: TextStyle(
                  fontSize: 13, color: AdminColors.textMuted)),
        ),
      );
    }
    return AdminCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menú del comercio',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
                AdminButton(
                  label: 'Agregar producto',
                  icon: Icons.add,
                  size: AdminBtnSize.sm,
                  onPressed: () => _openProductDialog(context),
                ),
              ],
            ),
          ),
          StreamBuilder<List<ProductModel>>(
            stream: StoreService.streamProducts(storeId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final products = snap.data!;
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('Este comercio aún no tiene productos.',
                        style: TextStyle(
                            fontSize: 13, color: AdminColors.textMuted)),
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < products.length; i++)
                    _ProductRow(
                      product: products[i],
                      onToggle: (v) => _toggleAvailable(products[i], v),
                      onEdit: () => _openProductDialog(context,
                          product: products[i]),
                      onDelete: () => _confirmDelete(context, products[i]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductRow({
    required this.product,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          _Thumb(url: product.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (product.description.isNotEmpty)
                  Text(product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AdminColors.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              product.category.isEmpty ? '—' : product.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5, color: AdminColors.textMuted),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _money(product.price),
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: product.isAvailable,
            activeThumbColor: AdminColors.primary,
            onChanged: onToggle,
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            splashRadius: 18,
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AdminColors.red),
            splashRadius: 18,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  const _Thumb({required this.url});
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AdminColors.grayTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.restaurant_menu,
            size: 18, color: AdminColors.textMuted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 40,
          height: 40,
          color: AdminColors.grayTint,
          child: const Icon(Icons.broken_image_outlined,
              size: 18, color: AdminColors.textMuted),
        ),
      ),
    );
  }
}

/// ─── Add / Edit product dialog ─────────────────────────────────────
class ProductDialog extends StatefulWidget {
  final String storeId;
  final ProductModel? product;
  final void Function(String, {bool error}) onSnack;
  const ProductDialog({
    super.key,
    required this.storeId,
    this.product,
    required this.onSnack,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

/// Holds the two controllers for one editable option row (name + price)
/// inside an option group in [ProductDialog].
class _OptionRow {
  final TextEditingController name;
  final TextEditingController price;

  _OptionRow({String name = '', String price = ''})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price);

  factory _OptionRow.fromOption(ProductOption o) => _OptionRow(
        name: o.name,
        price: o.price == 0 ? '' : o.price.toStringAsFixed(2),
      );

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _ProductDialogState extends State<ProductDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _imageUrl;
  late bool _isAvailable;

  /// Document id the product is (or will be) stored under. Pre-generated for
  /// new products so the image can be uploaded to
  /// `stores/{storeId}/products/{id}.jpg` before the first save.
  late final String _productId;

  // Option groups — mirror the customer app's product schema.
  late final List<_OptionRow> _sizes;
  late final List<_OptionRow> _extras;
  late final List<_OptionRow> _cutlery;

  bool _saving = false;
  bool _uploadingImage = false;
  String? _error;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _productId = p?.id ?? StoreService.newProductId(widget.storeId);
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price =
        TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(2));
    _category = TextEditingController(text: p?.category ?? '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    // Rebuild so the preview thumb tracks manual edits of the URL field too.
    _imageUrl.addListener(() {
      if (mounted) setState(() {});
    });
    _isAvailable = p?.isAvailable ?? true;
    _sizes = (p?.sizes ?? []).map(_OptionRow.fromOption).toList();
    _extras = (p?.extras ?? []).map(_OptionRow.fromOption).toList();
    _cutlery = (p?.cutlery ?? []).map(_OptionRow.fromOption).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _category.dispose();
    _imageUrl.dispose();
    for (final r in [..._sizes, ..._extras, ..._cutlery]) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
    } catch (e) {
      widget.onSnack('No se pudo abrir el selector de imagen: $e',
          error: true);
      return;
    }
    if (file == null) return; // user cancelled
    setState(() {
      _uploadingImage = true;
      _error = null;
    });
    try {
      final raw = await file.readAsBytes();
      // Compress client-side (≤900px wide, JPEG q80) to keep Storage small.
      final bytes = _compressToJpeg(raw);
      final url = await StoreService.uploadProductImage(
        widget.storeId,
        _productId,
        bytes,
        contentType: 'image/jpeg',
      );
      if (!mounted) return;
      setState(() {
        _imageUrl.text = url;
        _uploadingImage = false;
      });
      widget.onSnack(
          'Imagen subida. Guarda el producto para aplicar el cambio.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      widget.onSnack('No se pudo subir la imagen: $e', error: true);
    }
  }

  void _addRow(List<_OptionRow> group) =>
      setState(() => group.add(_OptionRow()));

  void _removeRow(List<_OptionRow> group, int index) =>
      setState(() => group.removeAt(index).dispose());

  /// Converts an option group's rows into [ProductOption]s. Fully-empty rows
  /// are skipped so trailing blanks don't block saving. Returns null (and sets
  /// [_error]) when a row is invalid.
  List<ProductOption>? _collect(List<_OptionRow> rows, String groupLabel) {
    final out = <ProductOption>[];
    for (final r in rows) {
      final name = r.name.text.trim();
      final priceText = r.price.text.trim().replaceAll(',', '.');
      if (name.isEmpty && priceText.isEmpty) continue;
      if (name.isEmpty) {
        _error = 'Cada opción de $groupLabel necesita un nombre.';
        return null;
      }
      final price = priceText.isEmpty ? 0.0 : double.tryParse(priceText);
      if (price == null || price < 0) {
        _error = 'Precio inválido en "$name" ($groupLabel).';
        return null;
      }
      out.add(ProductOption(name: name, price: price));
    }
    return out;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (name.isEmpty || price == null) {
      setState(() => _error = 'Nombre y un precio válido son obligatorios.');
      return;
    }
    final sizes = _collect(_sizes, 'tamaño');
    final extras = _collect(_extras, 'extras');
    final cutlery = _collect(_cutlery, 'cubiertos');
    if (sizes == null || extras == null || cutlery == null) {
      setState(() {}); // surface the _error set by _collect
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final model = ProductModel(
      id: _productId,
      name: name,
      description: _description.text.trim(),
      price: price,
      category: _category.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      isAvailable: _isAvailable,
      sizes: sizes,
      extras: extras,
      cutlery: cutlery,
    );
    try {
      if (_isEdit) {
        await StoreService.updateProduct(
            widget.storeId, widget.product!.id, model.toMap());
      } else {
        await StoreService.createProduct(widget.storeId, _productId, model);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSnack(_isEdit ? 'Producto actualizado.' : 'Producto agregado.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo guardar: $e';
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isEdit ? 'Editar producto' : 'Agregar producto',
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
              AdminTextField(label: 'Nombre *', controller: _name),
              const SizedBox(height: 12),
              AdminTextField(
                  label: 'Descripción', controller: _description),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AdminTextField(
                        label: 'Precio base (S/) *',
                        controller: _price,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminTextField(
                        label: 'Categoría', controller: _category),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProductImageField(
                controller: _imageUrl,
                uploading: _uploadingImage,
                onPick: _pickAndUploadImage,
              ),
              const SizedBox(height: 20),
              _OptionGroup(
                title: 'Tamaño',
                hint: 'Obligatorio · 1 · el precio reemplaza al precio base',
                addLabel: 'Agregar tamaño',
                rows: _sizes,
                onAdd: () => _addRow(_sizes),
                onRemove: (i) => _removeRow(_sizes, i),
              ),
              const SizedBox(height: 20),
              _OptionGroup(
                title: 'Extras',
                hint: 'Opcional · varios · se suma al total (0 = Gratis)',
                addLabel: 'Agregar extra',
                rows: _extras,
                onAdd: () => _addRow(_extras),
                onRemove: (i) => _removeRow(_extras, i),
              ),
              const SizedBox(height: 20),
              _OptionGroup(
                title: 'Cubiertos',
                hint: 'Opcional · varios · se suma al total (0 = Gratis)',
                addLabel: 'Agregar cubierto',
                rows: _cutlery,
                onAdd: () => _addRow(_cutlery),
                onRemove: (i) => _removeRow(_cutlery, i),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _isAvailable,
                    activeThumbColor: AdminColors.primary,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                  const SizedBox(width: 4),
                  Text(_isAvailable ? 'Disponible' : 'No disponible',
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
                      label: _isEdit ? 'Guardar' : 'Agregar',
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

/// Product image controls inside [ProductDialog]: a live preview thumb, the
/// primary "upload file" button, and the manual URL text field as fallback.
/// Both paths write into [controller], so the save flow keeps persisting the
/// existing `imageUrl` field unchanged.
class _ProductImageField extends StatelessWidget {
  final TextEditingController controller;
  final bool uploading;
  final VoidCallback onPick;
  const _ProductImageField({
    required this.controller,
    required this.uploading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final url = controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminEyebrow('IMAGEN DEL PRODUCTO'),
        const SizedBox(height: 10),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                color: AdminColors.grayTint,
                child: url.isEmpty
                    ? const Icon(Icons.restaurant_menu,
                        size: 20, color: AdminColors.textMuted)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            size: 20,
                            color: AdminColors.textMuted),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminButton(
                    label: url.isEmpty ? 'Subir imagen' : 'Reemplazar imagen',
                    icon: Icons.upload_outlined,
                    size: AdminBtnSize.sm,
                    loading: uploading,
                    onPressed: onPick,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Se sube a Firebase Storage y se guarda con el producto.',
                    style:
                        TextStyle(fontSize: 11, color: AdminColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdminTextField(
            label: 'URL de imagen (alternativa manual)',
            controller: controller),
      ],
    );
  }
}

/// Editable option group (Tamaño / Extras / Cubiertos): a titled list of
/// name+price rows with per-row delete and an "add" button.
class _OptionGroup extends StatelessWidget {
  final String title;
  final String hint;
  final String addLabel;
  final List<_OptionRow> rows;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _OptionGroup({
    required this.title,
    required this.hint,
    required this.addLabel,
    required this.rows,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(hint,
            style: const TextStyle(
                fontSize: 11, color: AdminColors.textMuted)),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Sin opciones.',
                style:
                    TextStyle(fontSize: 12, color: AdminColors.textMuted)),
          ),
        for (int i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: AdminTextField(
                      label: 'Nombre', controller: rows[i].name),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AdminTextField(
                    label: 'Precio (S/)',
                    controller: rows[i].price,
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(i),
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 20, color: AdminColors.red),
                  tooltip: 'Eliminar opción',
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: AdminButton(
            label: addLabel,
            icon: Icons.add,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm,
            onPressed: onAdd,
          ),
        ),
      ],
    );
  }
}

/// ─── Horarios tab ──────────────────────────────────────────────────
class _HorariosTab extends StatefulWidget {
  final Map<String, dynamic>? horarios;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _HorariosTab({required this.horarios, required this.onSave});

  @override
  State<_HorariosTab> createState() => _HorariosTabState();
}

class _HorariosTabState extends State<_HorariosTab> {
  late Map<String, _DayHours> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _days = {
      for (final id in _dayLabels.keys)
        id: _DayHours.fromMap(
            (widget.horarios?[id] as Map?)?.cast<String, dynamic>()),
    };
  }

  Future<void> _pick(String dayId, bool isOpen) async {
    final current = isOpen ? _days[dayId]!.open : _days[dayId]!.close;
    final picked = await showTimePicker(
      context: context,
      initialTime: _parse(current),
    );
    if (picked == null) return;
    final str =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isOpen) {
        _days[dayId] = _days[dayId]!.copyWith(open: str);
      } else {
        _days[dayId] = _days[dayId]!.copyWith(close: str);
      }
    });
  }

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final map = {for (final e in _days.entries) e.key: e.value.toMap()};
    await widget.onSave(map);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Horarios de atención',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final id in _dayLabels.keys)
            _DayRow(
              label: _dayLabels[id]!,
              hours: _days[id]!,
              onToggleClosed: (closed) => setState(
                  () => _days[id] = _days[id]!.copyWith(closed: closed)),
              onPickOpen: () => _pick(id, true),
              onPickClose: () => _pick(id, false),
            ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: AdminButton(
              label: 'Guardar horarios',
              icon: Icons.check,
              size: AdminBtnSize.md,
              loading: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHours {
  final String open;
  final String close;
  final bool closed;
  const _DayHours(
      {this.open = '11:00', this.close = '23:00', this.closed = false});

  factory _DayHours.fromMap(Map<String, dynamic>? m) => _DayHours(
        open: m?['open'] ?? '11:00',
        close: m?['close'] ?? '23:00',
        closed: m?['closed'] ?? false,
      );

  _DayHours copyWith({String? open, String? close, bool? closed}) => _DayHours(
        open: open ?? this.open,
        close: close ?? this.close,
        closed: closed ?? this.closed,
      );

  Map<String, dynamic> toMap() =>
      {'open': open, 'close': close, 'closed': closed};
}

class _DayRow extends StatelessWidget {
  final String label;
  final _DayHours hours;
  final ValueChanged<bool> onToggleClosed;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;
  const _DayRow({
    required this.label,
    required this.hours,
    required this.onToggleClosed,
    required this.onPickOpen,
    required this.onPickClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          if (hours.closed)
            const Expanded(
              child: Text('Cerrado',
                  style: TextStyle(
                      fontSize: 13, color: AdminColors.textMuted)),
            )
          else
            Expanded(
              child: Row(
                children: [
                  _TimeButton(label: hours.open, onTap: onPickOpen),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—',
                        style: TextStyle(color: AdminColors.textMuted)),
                  ),
                  _TimeButton(label: hours.close, onTap: onPickClose),
                ],
              ),
            ),
          Row(
            children: [
              Text(hours.closed ? 'Cerrado' : 'Abierto',
                  style: const TextStyle(
                      fontSize: 12, color: AdminColors.textMuted)),
              Switch(
                value: !hours.closed,
                activeThumbColor: AdminColors.primary,
                onChanged: (open) => onToggleClosed(!open),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AdminColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 14, color: AdminColors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.robotoMono(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// ─── Comisión tab ──────────────────────────────────────────────────
class _ComisionTab extends StatefulWidget {
  final StoreModel store;
  final Future<void> Function(double) onSave;
  const _ComisionTab({required this.store, required this.onSave});

  @override
  State<_ComisionTab> createState() => _ComisionTabState();
}

class _ComisionTabState extends State<_ComisionTab> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: (widget.store.commissionPct ?? 18).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pct = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (pct == null || pct < 0 || pct > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa un porcentaje válido (0–100).'),
        backgroundColor: AdminColors.red,
      ));
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(pct);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = widget.store.commissionUpdatedAt;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminEyebrow('COMISIÓN ACTUAL'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${(widget.store.commissionPct ?? 18).toStringAsFixed(0)}%',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                const Text('por pedido',
                    style: TextStyle(
                        fontSize: 13, color: AdminColors.textMuted)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              updatedAt == null
                  ? 'Sin cambios registrados.'
                  : 'Último cambio: ${_fmtDate(updatedAt)}',
              style: const TextStyle(
                  fontSize: 12.5, color: AdminColors.textMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: AdminTextField(
                label: 'Nueva comisión (%)',
                controller: _ctrl,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: AdminButton(
                label: 'Modificar comisión',
                icon: Icons.percent,
                size: AdminBtnSize.md,
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Ventas tab ────────────────────────────────────────────────────
class _VentasTab extends StatelessWidget {
  final Future<StoreMonthStats>? statsFuture;
  const _VentasTab({required this.statsFuture});

  @override
  Widget build(BuildContext context) {
    if (statsFuture == null) {
      return const AdminCard(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Guarda el comercio para ver sus ventas.',
              style: TextStyle(
                  fontSize: 13, color: AdminColors.textMuted)),
        ),
      );
    }
    return FutureBuilder<StoreMonthStats>(
      future: statsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AdminCard(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        if (snap.hasError) {
          return AdminCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No se pudieron cargar las ventas: ${snap.error}',
                  style: const TextStyle(
                      fontSize: 13, color: AdminColors.red)),
            ),
          );
        }
        final st = snap.data ?? StoreMonthStats.empty;
        final bars =
            st.dailyGross.isEmpty ? <double>[] : st.dailyGross.skip(1).toList();
        return AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ventas del mes',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                  Text(_money(st.gross),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: bars.every((b) => b == 0)
                    ? const Center(
                        child: Text('Sin ventas registradas este mes.',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: AdminColors.textMuted)),
                      )
                    : _BarChart(values: bars),
              ),
              const SizedBox(height: 18),
              _VentasMetric('Pedidos', '${st.orders}'),
              _VentasMetric('Ventas brutas', _money(st.gross)),
              _VentasMetric('Comisión Runa', _money(st.commission)),
              _VentasMetric('A pagar al comercio', _money(st.payout)),
              _VentasMetric('Cancelaciones',
                  '${st.cancellations} (${st.cancelRate.toStringAsFixed(1)}%)'),
            ],
          ),
        );
      },
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> values;
  const _BarChart({required this.values});
  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<double>(0, (a, b) => b > a ? b : a);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final h = maxV == 0 ? 0.0 : (values[i] / maxV) * 110;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: AdminColors.primary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _VentasMetric extends StatelessWidget {
  final String label;
  final String value;
  const _VentasMetric(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AdminColors.textMuted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// ─── Documentos tab (placeholder) ──────────────────────────────────
class _DocumentosTab extends StatelessWidget {
  const _DocumentosTab();
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Documentos',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AdminColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.folder_outlined,
                    size: 32, color: AdminColors.textMuted),
                SizedBox(height: 10),
                Text(
                  'La gestión de documentos (RUC, licencias, contratos) estará '
                  'disponible próximamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AdminColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
