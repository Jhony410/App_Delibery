import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Datos personales', true),
      ('Documentos enviados', true),
      ('Verificación', false),
    ];
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      _ReviewBadge(),
                      const SizedBox(height: 32),
                      const Text(
                        'Tu cuenta está\nen revisión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: CourierColors.text,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: CourierColors.textMuted,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                                text:
                                    'Estamos validando tus documentos. Te avisaremos por correo y SMS cuando esté listo. Suele tardar entre '),
                            TextSpan(
                              text: '24 a 48 horas',
                              style: TextStyle(
                                color: CourierColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: CourierColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: CourierColors.border),
                        ),
                        child: Column(
                          children: steps.map((s) => _StatusRow(s.$1, s.$2)).toList(),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 36,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CButton(
                    label: 'Contactar soporte',
                    icon: Icons.help_outline,
                    variant: CButtonVariant.ghost,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  CButton(
                    label: 'Cerrar sesión',
                    variant: CButtonVariant.surface,
                    onPressed: () async {
                      await AuthService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (_) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: CourierColors.warning.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CourierColors.surface,
              border: Border.all(color: CourierColors.warning, width: 3),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 64,
              color: CourierColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool done;
  const _StatusRow(this.label, this.done);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? CourierColors.online : CourierColors.surface2,
              border: done
                  ? null
                  : Border.all(
                      color: CourierColors.warning,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: done ? CourierColors.text : CourierColors.textMuted,
              ),
            ),
          ),
          Text(
            done ? 'OK' : 'En proceso',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: done ? CourierColors.online : CourierColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
