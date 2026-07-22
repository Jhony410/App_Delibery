import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../models/address_model.dart';
import '../services/cart_service.dart';
import 'addresses_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Checkout: elige dirección en /addresses (modo select). El carrito es el
  // único que avanza a /summary tras recibir la dirección elegida.
  Future<void> _goToCheckout() async {
    final chosen = await Navigator.pushNamed(context, '/addresses',
        arguments: AddressListMode.select);
    if (!mounted) return;
    if (chosen is AddressModel) {
      CartService.selectedAddress = chosen.street;
      CartService.selectedAddressRef = chosen.reference;
      Navigator.pushNamed(context, '/summary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = CartService.groups;
    final isEmpty = groups.isEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildAppBar(context),
              Expanded(
                child: isEmpty
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 220),
                        child: Column(
                          children: groups
                              .map((g) => _StoreGroup(
                                    group: g,
                                    onChanged: () => setState(() {}),
                                  ))
                              .toList(),
                        ),
                      ),
              ),
            ],
          ),
          if (!isEmpty)
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
                      onTap: _goToCheckout,
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

/// One store's items in the cart, with a header, its lines, and a per-store
/// subtotal + delivery fee.
class _StoreGroup extends StatelessWidget {
  final CartGroup group;
  final VoidCallback onChanged;
  const _StoreGroup({required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Store header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.storeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 1),
                      Text(
                          '${group.deliveryTime ?? '--'} min · S/ ${group.deliveryFee.toStringAsFixed(2)} envío',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: group.items.asMap().entries.map((e) {
                final item = e.value;
                final isLast = e.key == group.items.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isLast ? Colors.transparent : AppColors.border,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      ImgPlaceholder(
                          height: 64, width: 64, tone: item.tone, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                            if (item.note != null &&
                                item.note!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(item.note!,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted)),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _QtyControl(
                                  qty: item.qty,
                                  onIncrement: () {
                                    CartService.incrementEntry(item);
                                    onChanged();
                                  },
                                  onDecrement: () {
                                    CartService.decrementEntry(item);
                                    onChanged();
                                  },
                                ),
                                Text('S/ ${item.lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Per-store subtotal + fee
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                _TotalRow('Subtotal',
                    'S/ ${group.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 5),
                _TotalRow('Envío',
                    'S/ ${group.deliveryFee.toStringAsFixed(2)}'),
              ],
            ),
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
