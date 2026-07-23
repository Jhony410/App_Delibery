import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Static help / FAQ screen.
///
/// NOTE: The content below is STATIC on purpose — there is no support backend
/// or ticketing collection wired into the courier app yet. If a real support
/// channel is added later, replace these entries with live data.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = <(String, String)>[
    (
      '¿Cómo recibo pedidos?',
      'Activa el interruptor "En línea" en la pantalla de inicio. Cuando haya '
          'un pedido cercano disponible te llegará una oferta con 30 segundos '
          'para aceptarla.'
    ),
    (
      '¿Cómo cobro un pedido en efectivo?',
      'En la pantalla de entrega verás el monto exacto a cobrar. Recíbelo antes '
          'de marcar el pedido como entregado.'
    ),
    (
      '¿Cuándo recibo mis ganancias?',
      'Tus ganancias se acumulan en tu billetera. Los retiros se gestionan '
          'manualmente y se depositan a tu cuenta bancaria registrada.'
    ),
    (
      '¿Qué hago si falta un producto?',
      'Repórtalo en el comercio antes de salir. No marques el recojo hasta '
          'tener todos los productos del pedido.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CTopBar(title: 'Ayuda y soporte'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('PREGUNTAS FRECUENTES'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: CourierColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CourierColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: _faqs
                            .map((f) => ExpansionTile(
                                  iconColor: CourierColors.primary,
                                  collapsedIconColor: CourierColors.textMuted,
                                  title: Text(
                                    f.$1,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: CourierColors.text,
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 14),
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        f.$2,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: CourierColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('CONTACTO'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CourierColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CourierColors.border),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ContactRow(
                            icon: Icons.email_outlined,
                            label: 'soporte@delipuno.pe',
                          ),
                          SizedBox(height: 12),
                          _ContactRow(
                            icon: Icons.phone_outlined,
                            label: '+51 999 000 000',
                          ),
                          SizedBox(height: 12),
                          _ContactRow(
                            icon: Icons.schedule_outlined,
                            label: 'Lun a Dom · 8:00 – 22:00',
                          ),
                        ],
                      ),
                    ),
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

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: CourierColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CourierColors.text,
          ),
        ),
      ],
    );
  }
}
