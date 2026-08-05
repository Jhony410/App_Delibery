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
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _emailLoading = false;
  bool _googleLoading = false;
  bool _biometricLoading = false;
  bool _biometricReady = false;
  bool _obscure = true;

  bool get _busy => _emailLoading || _googleLoading || _biometricLoading;

  @override
  void initState() {
    super.initState();
    _loadBiometricAccess();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricAccess() async {
    final available = await BiometricAuthService.isBiometricAvailable();
    final saved = await BiometricAuthService.hasSavedLogin();
    final uid = AuthService.currentUid;
    final activeProtected =
        uid != null && await BiometricAuthService.hasAccessForUser(uid);
    if (mounted) {
      setState(() => _biometricReady = available && (saved || activeProtected));
    }
  }

  Future<void> _signInWithEmail() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _emailLoading = true);
    try {
      await AuthService.signInWithEmail(_email.text.trim(), _password.text);
      if (mounted) _openHome();
    } on FirebaseAuthException catch (error) {
      _showError(_firebaseMessage(error.code));
    } on AuthFlowException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('No pudimos iniciar sesión. Inténtalo nuevamente.');
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_busy) return;
    setState(() => _googleLoading = true);
    try {
      final profile = await AuthService.signInWithGoogle();
      if (!mounted || profile == null) return;
      _openHome();
    } on AuthFlowException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('No pudimos iniciar sesión con Google. Inténtalo nuevamente.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signInWithBiometrics() async {
    if (_busy || !_biometricReady) return;
    setState(() => _biometricLoading = true);
    try {
      final uid = AuthService.currentUid;
      if (uid != null && await BiometricAuthService.hasAccessForUser(uid)) {
        final authenticated = await BiometricAuthService.authenticate();
        if (!mounted) return;
        if (authenticated) _openHome();
        return;
      }

      final result = await BiometricAuthService.signInWithBiometrics();
      if (!mounted) return;
      if (result.success) {
        _openHome();
        return;
      }
      if (!result.canceled) {
        _showError(result.error ?? 'No pudimos ingresar con tu huella.');
        await _loadBiometricAccess();
      }
    } on BiometricUnavailableException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('No pudimos ingresar con tu huella.');
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Ingresa tu correo para recuperar la contraseña.');
      return;
    }
    try {
      await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te enviamos un enlace de recuperación.')),
      );
    } on FirebaseAuthException catch (error) {
      _showError(_firebaseMessage(error.code));
    } catch (_) {
      _showError('No pudimos enviar el enlace de recuperación.');
    }
  }

  String _firebaseMessage(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Correo o contraseña incorrectos.',
    'invalid-email' => 'El correo no es válido.',
    'user-disabled' => 'Esta cuenta fue deshabilitada.',
    'network-request-failed' => 'Sin conexión a internet.',
    'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
    _ => 'No pudimos iniciar sesión. Inténtalo nuevamente.',
  };

  void _openHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: context.colors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const DeliPunoLogo(size: 88),
                    const SizedBox(height: 12),
                    const DeliPunoWordmark(color: Colors.white, size: 38),
                    const SizedBox(height: 4),
                    Text(
                      'Delivery para todo Puno',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pide fácil en DeliPuno',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 22),
                      _GoogleButton(
                        loading: _googleLoading,
                        enabled: !_busy,
                        onPressed: _continueWithGoogle,
                      ),
                      const SizedBox(height: 22),
                      _DividerLabel(label: 'o ingresa con tu cuenta'),
                      const SizedBox(height: 18),
                      AppTextField(
                        icon: Icons.mail_outline_rounded,
                        placeholder: 'Correo electrónico',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty || !email.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        icon: Icons.lock_outline_rounded,
                        placeholder: 'Contraseña',
                        controller: _password,
                        obscure: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _signInWithEmail(),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Ingresa tu contraseña'
                            : null,
                        trailing: IconButton(
                          tooltip: _obscure
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Ingresar',
                        onTap: _busy ? null : _signInWithEmail,
                        isLoading: _emailLoading,
                      ),
                      if (_biometricReady) ...[
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Ingresar con huella',
                          variant: 'ghost',
                          onTap: _busy ? null : _signInWithBiometrics,
                          isLoading: _biometricLoading,
                          leading: Icon(
                            Icons.fingerprint_rounded,
                            color: colors.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '¿No tienes una cuenta?',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () =>
                                      Navigator.pushNamed(context, '/register'),
                            child: const Text('Regístrate'),
                          ),
                        ],
                      ),
                    ],
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

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _GoogleButton({
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            )
          : Row(
              children: [
                Image.asset('assets/icon/google_g.png', width: 22, height: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Continuar con Google',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 34),
              ],
            ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;
  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
