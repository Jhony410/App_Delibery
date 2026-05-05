import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets.dart';

class PickupScreen extends StatefulWidget {
  final OrderModel order;
  const PickupScreen({super.key, required this.order});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  late final List<bool> _checked;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.order.items.length, false);
  }

  bool get _canSubmit => _checked.every((c) => c);

  Future<void> _confirm() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      await OrderService.markPickedUp(widget.order.id);
      await OrderService.markEnRoute(widget.order.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/route-customer',
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
            const CTopBar(title: 'Confirmar recojo'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('EN'),
                          const SizedBox(height: 4),
                          Text(
                            order.storeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: CourierColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Marca cada producto al recibirlo:',
                      style: TextStyle(
                        fontSize: 14,
                        color: CourierColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: CourierColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CourierColors.border),
                      ),
                      child: Column(
                        children: List.generate(order.items.length, (i) {
                          final item = order.items[i];
                          final last = i == order.items.length - 1;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                setState(() => _checked[i] = !_checked[i]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: last
                                        ? Colors.transparent
                                        : CourierColors.borderSoft,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 120),
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _checked[i]
                                          ? CourierColors.online
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: _checked[i]
                                          ? null
                                          : Border.all(
                                              color: CourierColors.border,
                                              width: 2,
                                            ),
                                    ),
                                    alignment: Alignment.center,
                                    child: _checked[i]
                                        ? const Icon(Icons.check,
                                            size: 18,
                                            color: CourierColors.onOnline)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: _checked[i]
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: _checked[i]
                                            ? CourierColors.text
                                            : CourierColors.textMuted,
                                        decoration: _checked[i]
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '×${item.qty}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: CourierColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CourierColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.help_outline,
                              size: 18, color: CourierColors.warning),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '¿Falta un producto? Repórtalo antes de salir del comercio.',
                              style: TextStyle(
                                fontSize: 13,
                                color: CourierColors.textMuted,
                              ),
                            ),
                          ),
                        ],
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
                label: _saving
                    ? 'Guardando…'
                    : _canSubmit
                        ? 'Pedido recogido'
                        : 'Marca todos los productos',
                icon: Icons.check_rounded,
                size: CButtonSize.xl,
                onPressed: (_canSubmit && !_saving) ? _confirm : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
