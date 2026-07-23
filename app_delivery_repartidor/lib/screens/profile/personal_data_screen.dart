import 'package:flutter/material.dart';
import '../../models/courier_model.dart';
import '../../services/auth_service.dart';
import '../../services/courier_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Edit the courier's personal data (name, phone, DNI) on `couriers/{uid}`.
class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _dni = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dni.dispose();
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
    _name.text = c?.name ?? '';
    _phone.text = c?.phone ?? '';
    _dni.text = c?.dni ?? '';
    setState(() => _loading = false);
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'El nombre no puede estar vacío.';
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9\s]{6,15}$').hasMatch(phone)) {
      return 'El teléfono no es válido.';
    }
    final dni = _dni.text.trim();
    if (dni.isNotEmpty && !RegExp(r'^[0-9]{6,12}$').hasMatch(dni)) {
      return 'El DNI debe tener solo números (6 a 12 dígitos).';
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      _snack(error, ok: false);
      return;
    }
    final uid = AuthService.currentUid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await CourierService.updateCourier(uid, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'dni': _dni.text.trim(),
      });
      if (!mounted) return;
      _snack('Datos actualizados.', ok: true);
      Navigator.of(context).maybePop();
    } catch (_) {
      _snack('No se pudieron guardar los datos.', ok: false);
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
            const CTopBar(title: 'Datos personales'),
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
                            label: 'Nombre completo',
                            controller: _name,
                            placeholder: 'Tu nombre',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                          CField(
                            label: 'Teléfono',
                            controller: _phone,
                            placeholder: '999 999 999',
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: 14),
                          CField(
                            label: 'DNI',
                            controller: _dni,
                            placeholder: '12345678',
                            keyboardType: TextInputType.number,
                            icon: Icons.badge_outlined,
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
