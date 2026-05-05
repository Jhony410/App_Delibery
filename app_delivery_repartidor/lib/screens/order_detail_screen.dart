import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        child: StreamBuilder<OrderModel?>(
          stream: OrderService.streamOrder(order.id),
          initialData: order,
          builder: (context, snap) {
            final o = snap.data ?? order;
            return Column(
              children: [
                CTopBar(
                  title:
                      'Pedido #${o.id.length > 8 ? o.id.substring(0, 8).toUpperCase() : o.id.toUpperCase()}',
                  trailing: StatusPill(
                    text: o.statusLabel.toUpperCase(),
                    color: _statusColor(o.status),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (o.isCash) _CashCallout(amount: o.total),
                        const SizedBox(height: 14),
                        const SectionLabel('RECOGER EN'),
                        const SizedBox(height: 8),
                        _StoreCard(order: o),
                        const SizedBox(height: 14),
                        const SectionLabel('ENTREGAR A'),
                        const SizedBox(height: 8),
                        _CustomerCard(order: o),
                      ],
                    ),
                  ),
                ),
                _BottomCta(order: o),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'entregado' => CourierColors.online,
        'cancelado' => CourierColors.danger,
        'accepted' => CourierColors.online,
        'picked_up' => CourierColors.primary,
        'en_camino' => CourierColors.primary,
        _ => CourierColors.textMuted,
      };
}

class _CashCallout extends StatelessWidget {
  final double amount;
  const _CashCallout({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CourierColors.online,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.payments_rounded,
              size: 26,
              color: CourierColors.onOnline,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COBRA EN EFECTIVO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: CourierColors.onOnline,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'S/ ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
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
    );
  }
}

class _StoreCard extends StatelessWidget {
  final OrderModel order;
  const _StoreCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBox(
                icon: Icons.shopping_bag_outlined,
                background: CourierColors.primaryTint,
                color: CourierColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.storeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CourierColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.storeAddress ?? 'Comercio',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CourierColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const IconBox(
                icon: Icons.phone_outlined,
                background: CourierColors.surface2,
                color: CourierColors.text,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: CourierColors.border, height: 1),
          const SizedBox(height: 12),
          const SectionLabel('PRODUCTOS A RECOGER'),
          const SizedBox(height: 8),
          ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${it.qty}×',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CourierColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        it.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CourierColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final OrderModel order;
  const _CustomerCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          IconBox(
            icon: Icons.person_outline_rounded,
            background: CourierColors.onlineTint,
            color: CourierColors.online,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName ?? 'Cliente',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CourierColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CourierColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const IconBox(
            icon: Icons.phone_outlined,
            background: CourierColors.surface2,
            color: CourierColors.text,
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final OrderModel order;
  const _BottomCta({required this.order});

  @override
  Widget build(BuildContext context) {
    final (label, route, variant, icon) = switch (order.status) {
      'accepted' => (
          'Iniciar ruta al comercio',
          '/route-store',
          CButtonVariant.primary,
          Icons.navigation_rounded,
        ),
      'picked_up' => (
          'Iniciar ruta al cliente',
          '/route-customer',
          CButtonVariant.online,
          Icons.navigation_rounded,
        ),
      'en_camino' => (
          'Confirmar entrega',
          '/deliver',
          CButtonVariant.online,
          Icons.check_circle_outline,
        ),
      'entregado' => (
          'Volver al inicio',
          '/home',
          CButtonVariant.surface,
          Icons.home_outlined,
        ),
      _ => (
          'Iniciar ruta al comercio',
          '/route-store',
          CButtonVariant.primary,
          Icons.navigation_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: CourierColors.bg,
        border: Border(top: BorderSide(color: CourierColors.border)),
      ),
      child: CButton(
        label: label,
        icon: icon,
        size: CButtonSize.xl,
        variant: variant,
        onPressed: () {
          if (order.status == 'entregado') {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (_) => false);
          } else {
            Navigator.of(context).pushNamed(route, arguments: order);
          }
        },
      ),
    );
  }
}
