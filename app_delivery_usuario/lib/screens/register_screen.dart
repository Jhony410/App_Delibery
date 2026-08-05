import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await AuthService.signUpWithEmail(
        email: _email.text.trim(),
        password: _password.text,
        name: _name.text.trim(),
        phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } on FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'email-already-in-use' => 'Este correo ya está registrado.',
        'invalid-email' => 'El correo no es válido.',
        'weak-password' => 'Usa una contraseña de al menos 6 caracteres.',
        'network-request-failed' => 'Sin conexión a internet.',
        _ => 'No pudimos crear tu cuenta.',
      };
      _showError(message);
    } catch (_) {
      _showError('No pudimos crear tu cuenta. Inténtalo nuevamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Volver',
                        onPressed: _loading
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const DeliPunoLogo(size: 70),
                    const SizedBox(height: 8),
                    const DeliPunoWordmark(color: Colors.white, size: 32),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crear cuenta',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completa tus datos para comenzar',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 22),
                      AppTextField(
                        icon: Icons.person_outline_rounded,
                        placeholder: 'Nombre completo',
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (value) => (value?.trim().length ?? 0) < 3
                            ? 'Ingresa tu nombre completo'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        icon: Icons.phone_outlined,
                        placeholder: 'Celular',
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (value) {
                          final digits = (value ?? '').replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          return digits.length == 9
                              ? null
                              : 'Ingresa un celular de 9 dígitos';
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        icon: Icons.mail_outline_rounded,
                        placeholder: 'Correo electrónico',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return email.isEmpty || !email.contains('@')
                              ? 'Ingresa un correo válido'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        icon: Icons.lock_outline_rounded,
                        placeholder: 'Contraseña',
                        controller: _password,
                        obscure: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onSubmitted: (_) => _createAccount(),
                        validator: (value) => (value?.length ?? 0) < 6
                            ? 'Usa al menos 6 caracteres'
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
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Crear cuenta',
                        onTap: _loading ? null : _createAccount,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '¿Ya tienes una cuenta?',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Ingresar'),
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
