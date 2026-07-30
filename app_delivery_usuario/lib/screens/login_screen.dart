import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  /// Solo se muestra el botón de huella si el dispositivo la soporta Y el
  /// usuario ya activó la opción antes desde su perfil.
  bool _biometricReady = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await BiometricAuthService.isBiometricAvailable();
      final saved = await BiometricAuthService.hasSavedCredentials();
      if (mounted) setState(() => _biometricReady = available && saved);
    } catch (_) {
      // Sin biometría el formulario tradicional sigue intacto: no hay nada que
      // informarle al usuario.
    }
  }

  Future<void> _signInWithBiometrics() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final result = await BiometricAuthService.signInWithBiometrics();
      if (!mounted) return;
      if (result.isSuccess) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      // Cancelar no es un error: el usuario simplemente vuelve al formulario.
      if (result.canceled) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? 'No pudimos ingresar con tu huella'),
        backgroundColor: AppColors.danger,
      ));
      // Si las credenciales se borraron por estar obsoletas, el botón debe
      // desaparecer hasta que el usuario vuelva a activarlo desde su perfil.
      await _checkBiometrics();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No pudimos ingresar con tu huella'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthService.signIn(_email.text.trim(), _pass.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_friendlyError(e.toString())),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('invalid-credential') ||
        e.contains('user-not-found') ||
        e.contains('wrong-password')) {
      return 'Correo o contraseña incorrectos';
    }
    if (e.contains('network')) return 'Sin conexión a internet';
    return 'Ocurrió un error, inténtalo de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeliPunoWordmark(size: 40),
              const SizedBox(height: 32),
              const Text(
                'Bienvenida\nde vuelta',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa para pedir en minutos.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 32),
              AppTextField(
                icon: Icons.mail_outline,
                placeholder: 'Correo electrónico',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AppTextField(
                icon: Icons.lock_outline,
                placeholder: 'Contraseña',
                obscure: _obscure,
                controller: _pass,
                trailing: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    if (_email.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    await AuthService.sendPasswordReset(_email.text.trim());
                    messenger.showSnackBar(const SnackBar(
                      content: Text('Correo de recuperación enviado'),
                    ));
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : AppButton(label: 'Ingresar', onTap: _signIn),
              if (_biometricReady && !_loading) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Ingresar con huella',
                  variant: 'ghost',
                  onTap: _signInWithBiometrics,
                  leading: const Icon(Icons.fingerprint,
                      size: 22, color: AppColors.primary),
                ),
              ],
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: const TextSpan(
                      style:
                          TextStyle(fontSize: 14, color: AppColors.textMuted),
                      children: [
                        TextSpan(text: '¿Nuevo aquí? '),
                        TextSpan(
                          text: 'Crea una cuenta',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
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
