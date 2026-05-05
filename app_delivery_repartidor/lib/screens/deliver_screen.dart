import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/courier_service.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets.dart';

class DeliverScreen extends StatefulWidget {
  final OrderModel order;
  const DeliverScreen({super.key, required this.order});

  @override
  State<DeliverScreen> createState() => _DeliverScreenState();
}

class _DeliverScreenState extends State<DeliverScreen> {
  bool _photoTaken = false;
  bool _saving = false;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final uid = AuthService.currentUid;
      await OrderService.markDelivered(widget.order.id);
      if (uid != null) {
        await CourierService.incrementDelivery(
          uid,
          widget.order.courierEarning,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/completed',
        (route) => route.settings.name == '/home',
        arguments: widget.order,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const CTopBar(title: 'Confirmar entrega'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entregando a\n${order.customerName ?? 'cliente'}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.15,
                        color: CourierColors.text,
                      ),
                    ),
                    if (order.isCash) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: CourierColors.online,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.payments_rounded,
                                size: 28,
                                color: CourierColors.onOnline,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'COBRAR EN EFECTIVO',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: CourierColors.onOnline,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'S/ ${order.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: CourierColors.onOnline,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const SectionLabel('FOTO COMO PRUEBA (OPCIONAL)'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _photoTaken = !_photoTaken),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: CourierColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _photoTaken
                                ? CourierColors.online
                                : CourierColors.border,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: CourierColors.surface2,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _photoTaken
                                      ? Icons.check_rounded
                                      : Icons.camera_alt_outlined,
                                  size: 28,
                                  color: _photoTaken
                                      ? CourierColors.online
                                      : CourierColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _photoTaken
                                    ? 'Foto adjunta'
                                    : 'Tomar foto del paquete',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: CourierColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Recomendado si no hay nadie en casa',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CourierColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: CourierColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CourierColors.border),
                      ),
                      child: TextField(
                        controller: _noteCtrl,
                        maxLines: 3,
                        minLines: 2,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CourierColors.text,
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                          hintText: 'Agregar nota (opcional)…',
                          hintStyle: TextStyle(
                            color: CourierColors.textSubtle,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: CourierColors.bg,
                border: Border(top: BorderSide(color: CourierColors.border)),
              ),
              child: CButton(
                label: _saving ? 'Guardando…' : 'Entregado',
                icon: Icons.check_circle_outline,
                size: CButtonSize.xl,
                variant: CButtonVariant.online,
                onPressed: _saving ? null : _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
