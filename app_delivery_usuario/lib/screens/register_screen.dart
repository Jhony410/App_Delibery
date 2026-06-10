import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _terms = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _pass.text.isEmpty) {
      return;
    }
    if (!_terms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes aceptar los términos y condiciones'),
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.signUp(
        email: _email.text.trim(),
        password: _pass.text,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      if (mounted) Navigator.pushNamed(context, '/verify');
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
    if (e.contains('email-already-in-use')) return 'Este correo ya está registrado';
    if (e.contains('weak-password')) return 'La contraseña debe tener al menos 6 caracteres';
    if (e.contains('invalid-email')) return 'Correo inválido';
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chevron_left, size: 22),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Crea tu\ncuenta',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Te pediremos los datos una sola vez.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 28),
              AppTextField(
                icon: Icons.person_outline,
                placeholder: 'Nombre completo',
                controller: _name,
              ),
              const SizedBox(height: 12),
              AppTextField(
                icon: Icons.phone_outlined,
                placeholder: 'Teléfono (9 dígitos)',
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
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
              GestureDetector(
                onTap: () => setState(() => _terms = !_terms),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: _terms ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: _terms ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _terms
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: 'Acepto los '),
                            TextSpan(
                              text: 'Términos',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : AppButton(label: 'Crear cuenta', onTap: _signUp),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      style:
                          TextStyle(fontSize: 14, color: AppColors.textMuted),
                      children: [
                        TextSpan(text: '¿Ya tienes cuenta? '),
                        TextSpan(
                          text: 'Inicia sesión',
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
