import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes.dart';
import '../theme.dart';
import '../widgets/admin_widgets.dart';

/// Dev-only one-time bootstrap screen. Creates the Firebase Auth account and
/// the matching `admins/{uid}` document so the panel has at least one admin
/// to log in with. Remove the link from login once you're up and running.
class SetupAdminScreen extends StatefulWidget {
  const SetupAdminScreen({super.key});

  @override
  State<SetupAdminScreen> createState() => _SetupAdminScreenState();
}

class _SetupAdminScreenState extends State<SetupAdminScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _checking = true;
  bool _alreadyExists = false;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('admins')
          .limit(1)
          .get();
      if (!mounted) return;
      setState(() {
        _alreadyExists = snap.docs.isNotEmpty;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pass = _password.text;
    if (name.isEmpty || email.isEmpty || pass.length < 6) {
      setState(() => _error =
          'Completa nombre, correo y una contraseña de al menos 6 caracteres.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(cred.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': 'super_admin',
        'memberSince': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _success =
          'Cuenta creada. Redirigiendo al dashboard…');
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AdminRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _humanError(e.code));
    } catch (e) {
      setState(() => _error = 'No se pudo crear la cuenta. ($e)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _humanError(String code) => switch (code) {
        'email-already-in-use' =>
          'Ese correo ya está registrado. Usa "Iniciar sesión".',
        'invalid-email' => 'Correo no válido.',
        'weak-password' =>
          'La contraseña es muy débil. Usa al menos 6 caracteres.',
        'operation-not-allowed' =>
          'El método correo/contraseña no está habilitado en Firebase Auth.',
        'network-request-failed' => 'Sin conexión a internet.',
        _ => 'No se pudo crear la cuenta ($code).',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Container(
            width: 460,
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
                Row(
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
                    const AdminBadge('Setup inicial', tone: 'amber'),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Crear primer administrador',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                const Text(
                  'Esta pantalla crea la cuenta de Firebase Auth y el documento '
                  'en admins/{uid} en una sola operación. Quítala antes de '
                  'desplegar a producción.',
                  style:
                      TextStyle(fontSize: 13, color: AdminColors.textMuted),
                ),
                if (_checking) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AdminColors.primary),
                    ),
                  ),
                ] else ...[
                  if (_alreadyExists) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.amberTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16, color: AdminColors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ya existe al menos un admin en la base de datos. Crear otro está permitido pero verifica que sea intencional.',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: AdminColors.amber,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AdminTextField(
                    label: 'Nombre completo',
                    controller: _name,
                    icon: Icons.person_outline,
                    hint: 'Tu nombre',
                  ),
                  const SizedBox(height: 14),
                  AdminTextField(
                    label: 'Correo',
                    controller: _email,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'tu@correo.com',
                  ),
                  const SizedBox(height: 14),
                  AdminTextField(
                    label: 'Contraseña',
                    controller: _password,
                    icon: Icons.lock_outline,
                    obscure: true,
                    hint: 'Mínimo 6 caracteres',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _MessageBox(
                        text: _error!,
                        tone: 'red',
                        icon: Icons.error_outline),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 14),
                    _MessageBox(
                        text: _success!,
                        tone: 'green',
                        icon: Icons.check_circle_outline),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 42,
                    child: AdminButton(
                      label: _loading
                          ? 'Creando…'
                          : 'Crear administrador',
                      size: AdminBtnSize.lg,
                      variant: AdminBtnVariant.coral,
                      onPressed: _submit,
                      loading: _loading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AdminRoutes.login),
                      child: const Text('Ya tengo cuenta · Iniciar sesión',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AdminColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String text;
  final String tone;
  final IconData icon;
  const _MessageBox(
      {required this.text, required this.tone, required this.icon});

  @override
  Widget build(BuildContext context) {
    final bg = tone == 'red' ? AdminColors.redTint : AdminColors.greenTint;
    final fg = tone == 'red' ? AdminColors.red : AdminColors.green;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12.5,
                  color: fg,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
