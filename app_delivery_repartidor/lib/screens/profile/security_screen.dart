import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Real security options: change password (with reauthentication) and send a
/// password-reset email.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_current.text.isEmpty) {
      _snack('Ingresa tu contraseña actual.', ok: false);
      return;
    }
    if (_new.text.length < 6) {
      _snack('La nueva contraseña debe tener al menos 6 caracteres.',
          ok: false);
      return;
    }
    if (_new.text != _confirm.text) {
      _snack('Las contraseñas no coinciden.', ok: false);
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthService.changePassword(_current.text, _new.text);
      if (!mounted) return;
      _snack('Contraseña actualizada.', ok: true);
      _current.clear();
      _new.clear();
      _confirm.clear();
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
          'La contraseña actual es incorrecta.',
        'weak-password' => 'La nueva contraseña es demasiado débil.',
        'requires-recent-login' =>
          'Vuelve a iniciar sesión para cambiar la contraseña.',
        _ => 'No se pudo cambiar la contraseña.',
      };
      _snack(msg, ok: false);
    } catch (_) {
      _snack('No se pudo cambiar la contraseña.', ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendReset() async {
    final email = AuthService.currentUser?.email;
    if (email == null) return;
    try {
      await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      _snack('Te enviamos un correo para restablecer tu contraseña.', ok: true);
    } catch (_) {
      _snack('No se pudo enviar el correo.', ok: false);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CTopBar(title: 'Seguridad y privacidad'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('CAMBIAR CONTRASEÑA'),
                    const SizedBox(height: 12),
                    CField(
                      label: 'Contraseña actual',
                      controller: _current,
                      obscureText: true,
                      placeholder: '••••••••',
                      icon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    CField(
                      label: 'Nueva contraseña',
                      controller: _new,
                      obscureText: true,
                      placeholder: 'Mínimo 6 caracteres',
                      icon: Icons.lock_reset_rounded,
                    ),
                    const SizedBox(height: 14),
                    CField(
                      label: 'Confirmar nueva contraseña',
                      controller: _confirm,
                      obscureText: true,
                      placeholder: 'Repite la contraseña',
                      icon: Icons.lock_reset_rounded,
                    ),
                    const SizedBox(height: 18),
                    CButton(
                      label: _saving ? 'Guardando…' : 'Actualizar contraseña',
                      icon: Icons.check_rounded,
                      size: CButtonSize.lg,
                      onPressed: _saving ? null : _changePassword,
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('¿OLVIDASTE TU CONTRASEÑA?'),
                    const SizedBox(height: 12),
                    CButton(
                      label: 'Enviar correo de restablecimiento',
                      icon: Icons.email_outlined,
                      size: CButtonSize.lg,
                      variant: CButtonVariant.ghost,
                      onPressed: _sendReset,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
