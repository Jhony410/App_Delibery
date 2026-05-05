import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../theme.dart';
import '../widgets.dart';

class CompletedScreen extends StatelessWidget {
  final OrderModel order;
  const CompletedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final earning = order.courierEarning;
    final base = (earning * 0.6).clamp(1.0, double.infinity);
    final distancePay = earning - base;
    final tip = 0.0;

    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: CourierColors.onlineTint,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: CourierColors.online, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          size: 56,
                          color: CourierColors.online,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '¡Pedido entregado!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: CourierColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()} · ${_now()}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: CourierColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: CourierColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CourierColors.border),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'GANASTE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: CourierColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'S/ ${earning.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2.2,
                                color: CourierColors.online,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: CourierColors.border, height: 1),
                            const SizedBox(height: 14),
                            _Row('Pago base', 'S/ ${base.toStringAsFixed(2)}'),
                            const SizedBox(height: 10),
                            _Row('Distancia',
                                'S/ ${distancePay.toStringAsFixed(2)}'),
                            const SizedBox(height: 10),
                            _Row(
                              'Propina del cliente',
                              'S/ ${tip.toStringAsFixed(2)}',
                              valueColor: CourierColors.online,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: CourierColors.surface2,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Buen trabajo',
                              style: TextStyle(
                                fontSize: 13,
                                color: CourierColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '¡Sigue así! ✦',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: CourierColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CButton(
                label: 'Buscar nuevo pedido',
                size: CButtonSize.xl,
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (_) => false),
              ),
              const SizedBox(height: 10),
              CButton(
                label: 'Ver detalles',
                variant: CButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pushReplacementNamed(
                  '/order-detail',
                  arguments: order,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _now() {
    final n = DateTime.now();
    final hh = n.hour > 12 ? n.hour - 12 : (n.hour == 0 ? 12 : n.hour);
    final mm = n.minute.toString().padLeft(2, '0');
    final ampm = n.hour >= 12 ? 'PM' : 'AM';
    return 'Hoy $hh:$mm $ampm';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: CourierColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? CourierColors.text,
          ),
        ),
      ],
    );
  }
}
