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
  int _step = 0;
  bool _loading = false;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _dni = TextEditingController();
  final _vehiclePlate = TextEditingController();
  final _vehicleModel = TextEditingController();

  bool _docDniFront = false;
  bool _docDniBack = false;
  bool _docLicense = false;
  bool _docSoat = false;

  static const _stepLabels = ['Datos', 'Documentos', 'Vehículo', 'Foto'];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _dni.dispose();
    _vehiclePlate.dispose();
    _vehicleModel.dispose();
    super.dispose();
  }

  void _next() async {
    if (_step < 3) {
      if (_step == 0 && !_validateStep0()) return;
      setState(() => _step++);
      return;
    }
    await _submit();
  }

  bool _validateStep0() {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _password.text.length < 6) {
      setState(() =>
          _error = 'Completa todos los campos. La contraseña debe tener 6+ caracteres.');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.signUp(
        email: _email.text.trim(),
        password: _password.text,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        dni: _dni.text.trim(),
        vehiclePlate: _vehiclePlate.text.trim(),
        vehicleModel: _vehicleModel.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/review');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e.code));
    } catch (_) {
      setState(() => _error = 'No pudimos crear tu cuenta. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(String code) => switch (code) {
        'email-already-in-use' => 'Ese correo ya está registrado.',
        'invalid-email' => 'El correo no es válido.',
        'weak-password' => 'La contraseña es muy débil.',
        _ => 'No pudimos crear tu cuenta. Intenta de nuevo.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            CTopBar(
              title: 'Crear cuenta',
              onBack: () {
                if (_step == 0) {
                  Navigator.of(context).maybePop();
                } else {
                  setState(() => _step--);
                }
              },
            ),
            _Stepper(current: _step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _buildStep(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: CourierColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: CourierColors.border, width: 1),
                ),
              ),
              child: CButton(
                label: _step == 3 ? (_loading ? 'Enviando…' : 'Enviar a revisión') : 'Continuar',
                size: CButtonSize.xl,
                onPressed: _loading ? null : _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildPersonalData();
      case 1:
        return _buildDocuments();
      case 2:
        return _buildVehicle();
      case 3:
      default:
        return _buildPhoto();
    }
  }

  Widget _buildPersonalData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tus datos',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: CourierColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Empecemos por conocerte.',
          style: TextStyle(fontSize: 14, color: CourierColors.textMuted),
        ),
        const SizedBox(height: 24),
        CField(
          label: 'Nombre completo',
          icon: Icons.person_outline_rounded,
          controller: _name,
          placeholder: 'Julio Ramírez',
        ),
        const SizedBox(height: 12),
        CField(
          label: 'Correo',
          icon: Icons.mail_outline_rounded,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          placeholder: 'tucorreo@correo.com',
        ),
        const SizedBox(height: 12),
        CField(
          label: 'Teléfono',
          icon: Icons.phone_outlined,
          controller: _phone,
          keyboardType: TextInputType.phone,
          placeholder: '987 654 321',
        ),
        const SizedBox(height: 12),
        CField(
          label: 'DNI',
          icon: Icons.badge_outlined,
          controller: _dni,
          keyboardType: TextInputType.number,
          placeholder: '12345678',
        ),
        const SizedBox(height: 12),
        CField(
          label: 'Contraseña',
          icon: Icons.lock_outline_rounded,
          controller: _password,
          obscureText: true,
          placeholder: 'Mínimo 6 caracteres',
        ),
      ],
    );
  }

  Widget _buildDocuments() {
    final docs = [
      ('DNI · Anverso', _docDniFront, () => setState(() => _docDniFront = !_docDniFront)),
      ('DNI · Reverso', _docDniBack, () => setState(() => _docDniBack = !_docDniBack)),
      ('Licencia de conducir', _docLicense, () => setState(() => _docLicense = !_docLicense)),
      ('SOAT vigente', _docSoat, () => setState(() => _docSoat = !_docSoat)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sube tus documentos',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: CourierColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Necesitamos verificar tu identidad y permisos.',
          style: TextStyle(fontSize: 14, color: CourierColors.textMuted),
        ),
        const SizedBox(height: 24),
        ...docs.map((d) {
          final (label, done, toggle) = d;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: toggle,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CourierColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: done ? CourierColors.online : CourierColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    IconBox(
                      icon: done ? Icons.check_rounded : Icons.description_outlined,
                      background: done ? CourierColors.onlineTint : CourierColors.surface2,
                      color: done ? CourierColors.online : CourierColors.textMuted,
                      size: 52,
                      iconSize: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CourierColors.text,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            done ? '✓ Listo' : 'Toca para subir',
                            style: TextStyle(
                              fontSize: 12,
                              color: done
                                  ? CourierColors.online
                                  : CourierColors.textSubtle,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      done ? Icons.chevron_right : Icons.camera_alt_outlined,
                      size: 22,
                      color: CourierColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVehicle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tu vehículo',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: CourierColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '¿Con qué vas a repartir?',
          style: TextStyle(fontSize: 14, color: CourierColors.textMuted),
        ),
        const SizedBox(height: 24),
        CField(
          label: 'Marca y modelo',
          icon: Icons.two_wheeler_outlined,
          controller: _vehicleModel,
          placeholder: 'Honda Wave',
        ),
        const SizedBox(height: 12),
        CField(
          label: 'Placa',
          icon: Icons.confirmation_number_outlined,
          controller: _vehiclePlate,
          placeholder: 'B3M-482',
        ),
      ],
    );
  }

  Widget _buildPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto de perfil',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: CourierColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Esta foto la verán los comercios y los clientes.',
          style: TextStyle(fontSize: 14, color: CourierColors.textMuted),
        ),
        const SizedBox(height: 28),
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: CourierColors.surface,
              border: Border.all(
                color: CourierColors.border,
                width: 2,
                style: BorderStyle.solid,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: CourierColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 32,
                    color: CourierColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tomar foto',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CourierColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int current;
  const _Stepper({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = List.generate(4, (i) {
      return _StepDot(
        index: i + 1,
        label: _RegisterScreenState._stepLabels[i],
        active: i == current,
        done: i < current,
      );
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            steps[i],
            if (i < steps.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    height: 2,
                    color: i < current
                        ? CourierColors.online
                        : CourierColors.border,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  final bool done;

  const _StepDot({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final fill = done
        ? CourierColors.online
        : active
            ? CourierColors.primary
            : CourierColors.surface2;
    final borderColor = done
        ? CourierColors.online
        : active
            ? CourierColors.primary
            : CourierColors.border;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: (done || active)
                        ? Colors.white
                        : CourierColors.textSubtle,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: active ? CourierColors.text : CourierColors.textSubtle,
          ),
        ),
      ],
    );
  }
}
