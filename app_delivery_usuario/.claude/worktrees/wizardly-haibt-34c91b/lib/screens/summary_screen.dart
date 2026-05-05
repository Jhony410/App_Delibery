import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/cart_service.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  child: Column(
                    children: [
                      _Card(
                        child: Row(
                          children: [
                            _IconBox(
                              color: AppColors.primaryTint,
                              child: const Icon(Icons.location_on,
                                  size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ENTREGAR EN',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.06)),
                                  const SizedBox(height: 3),
                                  Text(CartService.selectedAddress,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  if (CartService.selectedAddressRef != null) ...[
                                    const SizedBox(height: 2),
                                    Text(CartService.selectedAddressRef!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted)),
                                  ],
                                ],
                              ),
                            ),
                            const Text('Cambiar',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Card(
                        child: Row(
                          children: [
                            _IconBox(
                              color: AppColors.secondaryTint,
                              child: const Icon(Icons.access_time,
                                  size: 20, color: AppColors.secondary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TIEMPO ESTIMADO',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.06)),
                                  const SizedBox(height: 3),
                                  Text(
                                      'Lo antes posible · ${CartService.deliveryTime ?? '--'} min',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 20, color: AppColors.textSubtle),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('TUS PRODUCTOS (${CartService.itemCount})',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.04)),
                      ),
                      const SizedBox(height: 8),
                      _Card(
                        child: Column(
                          children: items.asMap().entries.map((e) {
                            final isLast = e.key == items.length - 1;
                            return _OrderLine(
                              '${e.value.qty}×',
                              e.value.name,
                              e.value.lineTotal.toStringAsFixed(2),
                              isLast,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Card(
                        child: Column(
                          children: [
                            _BreakdownRow('Subtotal',
                                'S/ ${CartService.subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            _BreakdownRow('Costo de envío',
                                'S/ ${CartService.deliveryFee.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            _BreakdownRow('Servicio', 'S/ 2.00'),
                            const Divider(color: AppColors.border, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                                Text(
                                    'S/ ${(CartService.total + 2.0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                              ],
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: AppButton(
                label: 'Continuar al pago',
                onTap: () => Navigator.pushNamed(context, '/payment'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Resumen del pedido',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: child,
      );
}

class _IconBox extends StatelessWidget {
  final Color color;
  final Widget child;
  const _IconBox({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: child,
      );
}

class _OrderLine extends StatelessWidget {
  final String qty;
  final String name;
  final String price;
  final bool isLast;
  const _OrderLine(this.qty, this.name, this.price, this.isLast);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: isLast ? Colors.transparent : AppColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(
                width: 30,
                child: Text(qty,
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700))),
            Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w500))),
            Text('S/ $price',
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  const _BreakdownRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    const c = AppColors.textMuted;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: c)),
        Text(value,
            style: TextStyle(
                fontSize: 13, color: c, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
