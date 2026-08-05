import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../models/address_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'address_form_screen.dart';

/// Cómo se abrió la lista de direcciones.
/// - [manage]: gestión normal desde Inicio/Perfil.
/// - [select]: el checkout necesita elegir una; tocar una tarjeta la devuelve
///   con pop y el checkout continúa a /summary.
enum AddressListMode { manage, select }

/// Pantalla A — Mis direcciones. SOLO lista y gestión: no tiene formulario ni
/// mapa. El formulario vive en [AddressFormScreen] (ruta /address-form).
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  AddressListMode _mode = AddressListMode.manage;
  bool _resolved = false;
  bool _loading = true;
  bool _loadError = false;
  List<AddressModel> _addresses = [];

  bool get _isSelect => _mode == AddressListMode.select;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_resolved) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is AddressListMode) _mode = arg;
      _resolved = true;
      _load();
    }
  }

  Future<void> _load() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      setState(() {
        _addresses = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      var list = await DbService.getUserAddresses(uid);
      // Garantiza que siempre haya exactamente una predeterminada.
      if (list.isNotEmpty && !list.any((a) => a.isDefault)) {
        await DbService.setDefaultAddress(uid, list.first.id);
        list = await DbService.getUserAddresses(uid);
      }
      if (mounted) {
        setState(() {
          _addresses = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  Future<void> _openForm({AddressModel? edit}) async {
    final result = await Navigator.pushNamed(
      context,
      '/address-form',
      arguments: AddressFormArgs(
        mode: edit == null ? AddressFormMode.create : AddressFormMode.edit,
        address: edit,
      ),
    );
    if (result is AddressModel) {
      await _load();
    }
  }

  Future<void> _setDefault(AddressModel a) async {
    final uid = AuthService.currentUid;
    if (uid == null || a.isDefault) return;
    try {
      await DbService.setDefaultAddress(uid, a.id);
      await _load();
      _snack('Predeterminada actualizada');
    } catch (e) {
      _snack('No se pudo actualizar', error: true);
    }
  }

  Future<void> _delete(AddressModel a) async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar dirección'),
        content: Text('¿Eliminar "${a.street}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DbService.deleteAddress(uid, a.id);
      await _load();
      _snack('Dirección eliminada');
    } catch (e) {
      _snack('No se pudo eliminar', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(),
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(height: top + 8),
          _buildAppBar(),
          Expanded(
            child: _loading
                ? Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        AppSkeleton(height: 104),
                        SizedBox(height: 10),
                        AppSkeleton(height: 104),
                      ],
                    ),
                  )
                : _loadError
                ? AppStateView(
                    icon: Icons.cloud_off_rounded,
                    title: 'No pudimos cargar tus direcciones',
                    message: 'Revisa tu conexión e inténtalo nuevamente.',
                    actionLabel: 'Reintentar',
                    onAction: _load,
                  )
                : _addresses.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    itemCount: _addresses.length,
                    separatorBuilder: (context, i) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) => _buildCard(_addresses[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return AppStateView(
      icon: Icons.location_off_outlined,
      title: 'No tienes direcciones guardadas',
      message: 'Agrega tu primera dirección de entrega.',
      actionLabel: 'Agregar dirección',
      onAction: () => _openForm(),
    );
  }

  Widget _buildCard(AddressModel a) {
    return GestureDetector(
      onTap: _isSelect ? () => Navigator.pop(context, a) : null,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: a.isDefault
                ? AppColors.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: a.isDefault ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (!_isSelect)
              GestureDetector(
                onTap: () => _setDefault(a),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: _RadioDot(selected: a.isDefault),
                ),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: a.isDefault
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconFor(a.label),
                size: 20,
                color: a.isDefault
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.label.isEmpty ? 'Dirección' : a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (a.isDefault) ...[
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Principal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    a.street,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (a.reference != null && a.reference!.isNotEmpty)
                    Text(
                      a.reference!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            if (_isSelect)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.outline,
              )
            else ...[
              _iconBtn(Icons.edit_outlined, () => _openForm(edit: a)),
              const SizedBox(width: 4),
              _iconBtn(Icons.delete_outline, () => _delete(a), danger: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: danger
              ? AppColors.danger
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('trabajo') || l.contains('oficina')) {
      return Icons.work_outline;
    }
    if (l.contains('intersec')) return Icons.alt_route;
    return Icons.home_outlined;
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSelect ? 'Elegir dirección' : 'Mis direcciones',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.primary
            : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: selected
              ? AppColors.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: 2,
        ),
      ),
      child: selected ? Icon(Icons.check, size: 13, color: Colors.white) : null,
    );
  }
}
