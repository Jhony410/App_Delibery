import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final items = CartService.items;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildAppBar(context),
              if (CartService.storeName != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(CartService.storeName!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5)),
                              const SizedBox(height: 1),
                              Text(
                                  '${CartService.deliveryTime ?? '--'} min · S/ ${CartService.deliveryFee.toStringAsFixed(2)} envío',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 64, color: AppColors.border),
                            SizedBox(height: 16),
                            Text('Tu carrito está vacío',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 160),
                        child: Column(
                          children: [
                            ...items.asMap().entries.map((e) {
                              final i = e.value;
                              final idx = e.key;
                              final isLast = idx == items.length - 1;
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isLast
                                          ? Colors.transparent
                                          : AppColors.border,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ImgPlaceholder(
                                        height: 64,
                                        width: 64,
                                        tone: i.tone,
                                        radius: 12),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(i.name,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                          if (i.note != null &&
                                              i.note!.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(i.note!,
                                                style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color:
                                                        AppColors.textMuted)),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _QtyControl(
                                                qty: i.qty,
                                                onIncrement: () =>
                                                    setState(() =>
                                                        CartService.increment(idx)),
                                                onDecrement: () =>
                                                    setState(() =>
                                                        CartService.decrement(idx)),
                                              ),
                                              Text(
                                                  'S/ ${i.lineTotal.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TotalRow('Subtotal',
                      'S/ ${CartService.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _TotalRow('Envío',
                      'S/ ${CartService.deliveryFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  _TotalRow(
                      'Total', 'S/ ${CartService.total.toStringAsFixed(2)}',
                      bold: true),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Ir a pagar',
                    onTap: items.isEmpty
                        ? null
                        : () => Navigator.pushNamed(context, '/address'),
                  ),
                ],
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
            child: Text('Tu carrito',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          if (CartService.items.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => CartService.clear()),
              child: const Text('Vaciar',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _QtyControl(
      {required this.qty,
      required this.onIncrement,
      required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: const SizedBox(
                width: 28, child: Icon(Icons.remove, size: 14)),
          ),
          Text('$qty',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800)),
          GestureDetector(
            onTap: onIncrement,
            child: const SizedBox(
                width: 28,
                child: Icon(Icons.add, size: 14, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                color: bold ? AppColors.appText : AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                color: bold ? AppColors.appText : AppColors.textMuted)),
      ],
    );
  }
}
