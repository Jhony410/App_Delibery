import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePass = true;
  bool _loading = false;
  String? _error;

  /// Solo se muestra el botón de huella si el dispositivo la soporta Y el
  /// repartidor ya activó la opción antes desde Seguridad y privacidad.
  bool _biometricReady = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await BiometricAuthService.isBiometricAvailable();
      final saved = await BiometricAuthService.hasSavedCredentials();
      if (mounted) setState(() => _biometricReady = available && saved);
    } catch (_) {
      // Sin biometría el formulario tradicional sigue intacto: no hay nada que
      // informarle al repartidor.
    }
  }

  Future<void> _signInWithBiometrics() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await BiometricAuthService.signInWithBiometrics();
      if (!mounted) return;
      final courier = result.courier;
      if (courier != null) {
        if (courier.status == 'pending_review') {
          Navigator.of(context).pushReplacementNamed('/review');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }
      // Cancelar no es un error: el repartidor vuelve al formulario sin ruido.
      if (result.canceled) return;
      setState(() => _error = result.error);
      // Si las credenciales se borraron por estar obsoletas, el botón debe
      // desaparecer hasta que vuelva a activarlo desde Seguridad.
      await _checkBiometrics();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pudimos ingresar con tu huella.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courier = await AuthService.signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (!mounted) return;
      if (courier == null) {
        setState(() => _error = 'No encontramos tu cuenta de repartidor.');
        await AuthService.signOut();
      } else if (courier.status == 'pending_review') {
        Navigator.of(context).pushReplacementNamed('/review');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e.code));
    } catch (_) {
      setState(() => _error = 'No pudimos iniciar sesión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(String code) => switch (code) {
        'invalid-email' => 'El correo no es válido.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Correo o contraseña incorrectos.',
        'too-many-requests' =>
          'Demasiados intentos. Espera unos minutos.',
        _ => 'No pudimos iniciar sesión. Intenta de nuevo.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: CourierColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.two_wheeler_rounded,
                    size: 36, color: Colors.white),
              ),
              const SizedBox(height: 30),
              const Text(
                'Hola repartidor',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: CourierColors.text,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa para empezar a entregar.',
                style: TextStyle(
                  fontSize: 15,
                  color: CourierColors.textMuted,
                ),
              ),
              const SizedBox(height: 36),
              CField(
                label: 'Correo',
                icon: Icons.mail_outline_rounded,
                placeholder: 'tucorreo@correo.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CField(
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                placeholder: '••••••••',
                controller: _passCtrl,
                obscureText: _hidePass,
                suffix: GestureDetector(
                  onTap: () => setState(() => _hidePass = !_hidePass),
                  child: Icon(
                    _hidePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: CourierColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: 14,
                    color: CourierColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CourierColors.dangerTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: CourierColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              CButton(
                label: _loading ? 'Ingresando…' : 'Ingresar',
                size: CButtonSize.xl,
                onPressed: _loading ? null : _signIn,
              ),
              if (_biometricReady) ...[
                const SizedBox(height: 12),
                CButton(
                  label: 'Ingresar con huella',
                  icon: Icons.fingerprint_rounded,
                  size: CButtonSize.xl,
                  variant: CButtonVariant.ghost,
                  onPressed: _loading ? null : _signInWithBiometrics,
                ),
              ],
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/register'),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: CourierColors.textMuted,
                      ),
                      children: [
                        TextSpan(text: '¿Quieres ser repartidor? '),
                        TextSpan(
                          text: 'Regístrate',
                          style: TextStyle(
                            color: CourierColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
