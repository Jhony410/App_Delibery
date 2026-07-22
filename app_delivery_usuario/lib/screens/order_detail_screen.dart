import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../models/order_model.dart';
import '../services/cart_service.dart';

/// Detail view for a finished order (opened from "Mis pedidos" when the order
/// is no longer active). Shows the line items, price breakdown, delivery
/// address and date, plus "Volver a pedir" and "Calificar" actions.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as OrderModel?;
    final top = MediaQuery.of(context).padding.top;

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _appBar(context),
              const Expanded(
                child: Center(
                  child: Text('Pedido no encontrado',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final canRate = order.status == 'entregado' && !order.rated;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: top + 8),
          _appBar(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _storeHeader(order),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Productos',
                  child: Column(
                    children: [
                      for (final it in order.items) _itemRow(it),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Resumen',
                  child: Column(
                    children: [
                      _priceRow('Subtotal',
                          'S/ ${order.subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _priceRow('Envío',
                          'S/ ${order.deliveryFee.toStringAsFixed(2)}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          Text('S/ ${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Entrega',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.location_on_outlined,
                          order.address.isEmpty ? '—' : order.address),
                      const SizedBox(height: 10),
                      _infoRow(Icons.calendar_today_outlined,
                          _formatDate(order.createdAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Volver a pedir',
                  onTap: () => _reorder(context, order),
                ),
                if (canRate) ...[
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Calificar',
                    variant: 'ghost',
                    onTap: () => Navigator.pushNamed(context, '/rating',
                        arguments: order.id),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reorder(BuildContext context, OrderModel order) {
    // Reconstruye las líneas de carrito a partir de los ítems del pedido y
    // fija el contexto de tienda que usa el checkout (payment_screen lee
    // CartService.storeId/storeName/storeTone para crear la nueva orden).
    CartService.setStore(
      id: order.storeId,
      name: order.storeName,
      tone: order.storeTone,
      time: '',
      fee: order.deliveryFee,
    );
    for (final it in order.items) {
      CartService.addOrIncrement(CartEntry(
        productId: it.productId,
        name: it.name,
        note: it.note,
        tone: order.storeTone,
        unitPrice: it.price,
        qty: it.qty,
        storeId: order.storeId,
        storeName: order.storeName,
        storeTone: order.storeTone,
        deliveryTime: null,
        deliveryFee: order.deliveryFee,
      ));
    }
    Navigator.pushNamed(context, '/cart');
  }

  Widget _storeHeader(OrderModel order) {
    return Row(
      children: [
        ImgPlaceholder(
            height: 56, width: 56, tone: order.storeTone, radius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.storeName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(order.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(order.status))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.04)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _itemRow(OrderItem it) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${it.qty}×',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (it.note != null && it.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(it.note!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSubtle)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('S/ ${(it.price * it.qty).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 14, height: 1.35)),
        ),
      ],
    );
  }

  Widget _appBar(BuildContext context) {
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Detalle del pedido',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'entregado') return AppColors.secondary;
    if (status == 'cancelado') return AppColors.danger;
    return AppColors.primary;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · '
        '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
