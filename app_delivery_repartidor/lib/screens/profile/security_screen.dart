import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_auth_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Real security options: change password (with reauthentication), send a
/// password-reset email, and enable biometric quick access.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final _bioPass = TextEditingController();
  bool _saving = false;

  bool _bioAvailable = false;
  bool _bioEnabled = false;
  bool _bioBusy = false;
  bool _bioLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    _bioPass.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    try {
      final available = await BiometricAuthService.isBiometricAvailable();
      final enabled = await BiometricAuthService.hasSavedCredentials();
      if (!mounted) return;
      setState(() {
        _bioAvailable = available;
        _bioEnabled = enabled;
        _bioLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _bioLoaded = true);
    }
  }

  /// Activar exige la contraseña actual aunque haya sesión abierta: no está en
  /// memoria, y guardarla sin verificarla dejaría un acceso con huella que
  /// fallaría siempre.
  Future<void> _enableBiometrics() async {
    final email = AuthService.currentUser?.email;
    if (email == null) {
      _snack('No hay una sesión activa.', ok: false);
      return;
    }
    if (_bioPass.text.isEmpty) {
      _snack('Ingresa tu contraseña para activar la huella.', ok: false);
      return;
    }
    setState(() => _bioBusy = true);
    try {
      // Primero la huella: sin verificarla no tiene sentido guardar nada.
      final verified = await BiometricAuthService.authenticate(
        reason: 'Verifica tu huella para activar el acceso rápido',
      );
      if (!verified) {
        if (mounted) setState(() => _bioBusy = false);
        return;
      }
      await BiometricAuthService.saveCredentials(email, _bioPass.text);
      if (!mounted) return;
      _bioPass.clear();
      setState(() => _bioEnabled = true);
      _snack('Acceso con huella activado.', ok: true);
    } on BiometricUnavailableException catch (e) {
      _snack(e.message, ok: false);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
          'La contraseña es incorrecta.',
        'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
        _ => 'No se pudo activar el acceso con huella.',
      };
      _snack(msg, ok: false);
    } catch (_) {
      _snack('No se pudo activar el acceso con huella.', ok: false);
    } finally {
      if (mounted) setState(() => _bioBusy = false);
    }
  }

  Future<void> _disableBiometrics() async {
    setState(() => _bioBusy = true);
    try {
      await BiometricAuthService.clearCredentials();
      if (!mounted) return;
      setState(() => _bioEnabled = false);
      _snack('Acceso con huella desactivado.', ok: true);
    } catch (_) {
      _snack('No se pudo desactivar el acceso con huella.', ok: false);
    } finally {
      if (mounted) setState(() => _bioBusy = false);
    }
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

  /// Tres estados posibles: sin soporte en el dispositivo, activo (solo se
  /// puede desactivar) o inactivo (pide la contraseña para activarlo).
  List<Widget> _buildBiometricSection() {
    if (!_bioLoaded) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Comprobando el sensor…',
            style: TextStyle(fontSize: 13, color: CourierColors.textMuted),
          ),
        ),
      ];
    }
    if (!_bioAvailable) {
      return const [
        Text(
          'Este dispositivo no tiene huella registrada o no cuenta con sensor '
          'biométrico. Puedes seguir ingresando con tu correo y contraseña.',
          style: TextStyle(fontSize: 13, color: CourierColors.textMuted),
        ),
      ];
    }
    if (_bioEnabled) {
      return [
        const Text(
          'Ya puedes ingresar con tu huella desde la pantalla de inicio de '
          'sesión. Tus datos están cifrados en este dispositivo.',
          style: TextStyle(fontSize: 13, color: CourierColors.textMuted),
        ),
        const SizedBox(height: 14),
        CButton(
          label: _bioBusy ? 'Desactivando…' : 'Desactivar acceso con huella',
          icon: Icons.fingerprint_rounded,
          size: CButtonSize.lg,
          variant: CButtonVariant.danger,
          onPressed: _bioBusy ? null : _disableBiometrics,
        ),
      ];
    }
    return [
      const Text(
        'Ingresa más rápido usando tu huella. Tus datos se guardan cifrados en '
        'este dispositivo, nunca en internet.',
        style: TextStyle(fontSize: 13, color: CourierColors.textMuted),
      ),
      const SizedBox(height: 14),
      CField(
        label: 'Confirma tu contraseña',
        controller: _bioPass,
        obscureText: true,
        placeholder: '••••••••',
        icon: Icons.lock_outline_rounded,
      ),
      const SizedBox(height: 14),
      CButton(
        label: _bioBusy ? 'Activando…' : 'Activar acceso con huella',
        icon: Icons.fingerprint_rounded,
        size: CButtonSize.lg,
        onPressed: _bioBusy ? null : _enableBiometrics,
      ),
    ];
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
                    const SizedBox(height: 24),
                    const SectionLabel('ACCESO CON HUELLA'),
                    const SizedBox(height: 12),
                    ..._buildBiometricSection(),
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
