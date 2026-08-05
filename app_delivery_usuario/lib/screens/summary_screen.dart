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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 100),
                  child: Column(
                    children: [
                      _Card(
                        child: Row(
                          children: [
                            _IconBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Icon(
                                Icons.location_on,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ENTREGAR EN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.06,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    CartService.selectedAddress,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (CartService.selectedAddressRef !=
                                      null) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      CartService.selectedAddressRef!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cambiar'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      _Card(
                        child: Row(
                          children: [
                            _IconBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              child: Icon(
                                Icons.access_time,
                                size: 20,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TIEMPO ESTIMADO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.06,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Lo antes posible · ${CartService.cartDeliveryTime ?? '--'} min',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TUS PRODUCTOS (${CartService.itemCount})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.04,
                          ),
                        ),
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
                              note: e.value.note,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Card(
                        child: Column(
                          children: [
                            _BreakdownRow(
                              'Subtotal',
                              'S/ ${CartService.subtotal.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8),
                            _BreakdownRow(
                              'Costo de envío',
                              'S/ ${CartService.deliveryFee.toStringAsFixed(2)}',
                            ),
                            Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'S/ ${CartService.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
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
                20,
                16,
                20,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
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
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Resumen del pedido',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
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
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
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
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _OrderLine extends StatelessWidget {
  final String qty;
  final String name;
  final String price;
  final bool isLast;
  final String? note;
  const _OrderLine(this.qty, this.name, this.price, this.isLast, {this.note});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: isLast
              ? Colors.transparent
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            qty,
            style: TextStyle(
              fontSize: 13.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
              if (note != null && note!.isNotEmpty) ...[
                SizedBox(height: 2),
                Text(
                  note!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          'S/ $price',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
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
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: c)),
        Text(
          value,
          style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
