import 'package:flutter/material.dart';
import '../../models/courier_model.dart';
import '../../services/auth_service.dart';
import '../../services/courier_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Edit the courier's `bankAccount` (used for manual withdrawals).
class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final _account = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _account.dispose();
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
    _account.text = c?.bankAccount ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    final acc = _account.text.trim();
    if (acc.isNotEmpty && !RegExp(r'^[0-9\s-]{8,30}$').hasMatch(acc)) {
      _snack('El número de cuenta no es válido.', ok: false);
      return;
    }
    setState(() => _saving = true);
    try {
      await CourierService.updateCourier(uid, {'bankAccount': acc});
      if (!mounted) return;
      _snack('Cuenta bancaria actualizada.', ok: true);
      Navigator.of(context).maybePop();
    } catch (_) {
      _snack('No se pudo guardar la cuenta.', ok: false);
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
            const CTopBar(title: 'Cuenta bancaria'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: CourierColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CField(
                            label: 'Número de cuenta / CCI',
                            controller: _account,
                            placeholder: '00212345678900123456',
                            keyboardType: TextInputType.number,
                            icon: Icons.credit_card_outlined,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Esta cuenta se usa para el depósito manual de tus '
                            'ganancias.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: CourierColors.textMuted,
                            ),
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
