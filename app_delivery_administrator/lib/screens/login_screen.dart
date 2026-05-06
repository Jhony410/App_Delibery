import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/admin_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'admin@runa.pe');
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.signIn(_email.text, _password.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AdminRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _humanError(e.code));
    } catch (e) {
      setState(() => _error = 'No se pudo iniciar sesión. ($e)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _humanError(String code) => switch (code) {
        'invalid-email' => 'Correo no válido.',
        'user-not-found' => 'No existe una cuenta con ese correo.',
        'wrong-password' || 'invalid-credential' =>
          'Credenciales incorrectas.',
        'user-disabled' => 'Cuenta deshabilitada.',
        'network-request-failed' => 'Sin conexión a internet.',
        _ => 'No se pudo iniciar sesión ($code).',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Stack(
        children: [
          // Dotted background
          Positioned.fill(
            child: CustomPaint(painter: _DotsPainter()),
          ),
          // Brand badge top-left
          Positioned(
            top: 32,
            left: 32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AdminColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text('R',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.4),
                        children: const [
                          TextSpan(text: 'runa'),
                          TextSpan(
                              text: '.',
                              style:
                                  TextStyle(color: AdminColors.primary)),
                        ],
                      ),
                    ),
                    Text('ADMIN PANEL',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AdminColors.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4)),
                  ],
                ),
              ],
            ),
          ),
          // Card
          Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AdminColors.border),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 50,
                      offset: Offset(0, 20)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Iniciar sesión',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6)),
                  const SizedBox(height: 6),
                  Text('Ingresa con tu cuenta corporativa.',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: AdminColors.textMuted)),
                  const SizedBox(height: 24),
                  AdminTextField(
                    label: 'Correo',
                    controller: _email,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'tu@runa.pe',
                  ),
                  const SizedBox(height: 14),
                  AdminTextField(
                    label: 'Contraseña',
                    controller: _password,
                    icon: Icons.lock_outline,
                    obscure: true,
                    trailingLabel: '¿Olvidaste?',
                    hint: '••••••••••••',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AdminColors.redTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: AdminColors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AdminColors.red,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 42,
                    child: AdminButton(
                      label: _loading ? 'Ingresando…' : 'Continuar',
                      size: AdminBtnSize.lg,
                      onPressed: _submit,
                      loading: _loading,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 14, color: AdminColors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Conexión segura · 2FA activado',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AdminColors.textMuted)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, '/setup'),
                      child: Text('¿Primera vez? Crear cuenta admin',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AdminColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text('© 2026 Runa · v3.2.1',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AdminColors.textSubtle)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4D4D8).withValues(alpha: 0.5);
    const step = 32.0;
    for (double y = 2; y < size.height; y += step) {
      for (double x = 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
