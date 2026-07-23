import 'package:flutter/material.dart';
import '../../models/courier_model.dart';
import '../../services/auth_service.dart';
import '../../services/courier_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Edit the courier's vehicle (`vehicleModel`, `vehiclePlate`).
class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _model = TextEditingController();
  final _plate = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _model.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final CourierModel? c = await CourierService.getCourier(uid);
    if (!mounted) return;
    _model.text = c?.vehicleModel ?? '';
    _plate.text = c?.vehiclePlate ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    final plate = _plate.text.trim();
    if (plate.isNotEmpty && plate.length < 4) {
      _snack('La placa no es válida.', ok: false);
      return;
    }
    setState(() => _saving = true);
    try {
      await CourierService.updateCourier(uid, {
        'vehicleModel': _model.text.trim(),
        'vehiclePlate': plate.toUpperCase(),
      });
      if (!mounted) return;
      _snack('Vehículo actualizado.', ok: true);
      Navigator.of(context).maybePop();
    } catch (_) {
      _snack('No se pudo guardar el vehículo.', ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? CourierColors.online : CourierColors.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const CTopBar(title: 'Mi vehículo'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: CourierColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        children: [
                          CField(
                            label: 'Modelo',
                            controller: _model,
                            placeholder: 'Ej. Honda Wave 110',
                            icon: Icons.two_wheeler_outlined,
                          ),
                          const SizedBox(height: 14),
                          CField(
                            label: 'Placa',
                            controller: _plate,
                            placeholder: 'Ej. ABC-123',
                            icon: Icons.pin_outlined,
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: CourierColors.bg,
                border: Border(top: BorderSide(color: CourierColors.border)),
              ),
              child: CButton(
                label: _saving ? 'Guardando…' : 'Guardar cambios',
                icon: Icons.check_rounded,
                size: CButtonSize.xl,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
