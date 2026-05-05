import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/cart_service.dart';
import '../services/db_service.dart';
import '../models/order_model.dart';

class ConfirmedScreen extends StatefulWidget {
  const ConfirmedScreen({super.key});

  @override
  State<ConfirmedScreen> createState() => _ConfirmedScreenState();
}

class _ConfirmedScreenState extends State<ConfirmedScreen> {
  static const _dots = [
    (40.0, 120.0, AppColors.primary),
    (330.0, 150.0, AppColors.secondary),
    (60.0, 580.0, AppColors.star),
    (300.0, 560.0, AppColors.primary),
    (150.0, 80.0, AppColors.secondary),
    (280.0, 80.0, AppColors.star),
    (80.0, 200.0, AppColors.star),
    (320.0, 240.0, AppColors.primary),
    (40.0, 520.0, AppColors.secondary),
  ];

  late final Future<OrderModel?> _future;
  late final String _orderId;
  late final String _shortId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _orderId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
      _shortId = _orderId.length > 6
          ? _orderId.substring(_orderId.length - 6).toUpperCase()
          : _orderId.toUpperCase();
      _future = _orderId.isNotEmpty
          ? DbService.getOrder(_orderId)
          : Future.value(null);
      _initialized = true;
    }
  }

  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Confeti decorativo
          ..._dots.asMap().entries.map((e) {
            final d = e.value;
            final isCircle = e.key < 6;
            return Positioned(
              left: d.$1,
              top: d.$2,
              child: isCircle
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: d.$3),
                    )
                  : Transform.rotate(
                      angle: 0.785,
                      child: Container(width: 6, height: 6, color: d.$3),
                    ),
            );
          }),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  // ── Ícono de éxito ──────────────────────────────
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryTint,
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                        ),
                        child: const Icon(Icons.check, size: 48, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    '¡Pedido confirmado!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.78),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                          height: 1.5),
                      children: [
                        const TextSpan(text: 'Tu pedido '),
                        TextSpan(
                          text: '#RN-$_shortId',
                          style: const TextStyle(
                              color: AppColors.appText,
                              fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: '\nya está siendo preparado.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Tiempo estimado ─────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 22, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tiempo estimado de entrega',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              CartService.lastDeliveryTime != null
                                  ? '${CartService.lastDeliveryTime} min'
                                  : '25 – 35 min',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Resumen del pedido ──────────────────────────
                  FutureBuilder<OrderModel?>(
                    future: _future,
                    builder: (context, snap) {
                      final order = snap.data;
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        );
                      }
                      if (order == null) return const SizedBox.shrink();

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(order.storeName,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...order.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: AppColors.bg,
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                        child: Center(
                                          child: Text('${item.qty}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textMuted)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(item.name,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500))),
                                      Text(
                                          'S/ ${item.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                )),
                            const Divider(color: AppColors.border, height: 16),
                            _InfoRow('Subtotal',
                                'S/ ${order.subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 4),
                            _InfoRow('Envío',
                                'S/ ${order.deliveryFee.toStringAsFixed(2)}'),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total pagado',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                Text('S/ ${order.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.payment,
                                      size: 15, color: AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    _payLabel(order.paymentMethod),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            if (order.observation != null &&
                                order.observation!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8F0),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFFFDFBC)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.comment_outlined,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(order.observation!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                              height: 1.4)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Botones ─────────────────────────────────────
                  AppButton(
                    label: 'Seguir mi pedido',
                    onTap: () => Navigator.pushNamed(context, '/tracking',
                        arguments: _orderId),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Volver al inicio',
                    variant: 'ghost',
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (_) => false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _payLabel(String method) => switch (method) {
        'yape' => 'Pagado con Yape',
        'plin' => 'Pagado con Plin',
        'card' => 'Tarjeta de crédito/débito',
        'cash' => 'Efectivo al repartidor',
        _ => method,
      };
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
