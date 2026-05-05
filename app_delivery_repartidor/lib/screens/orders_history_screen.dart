import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  int _filter = 0;
  static const _filterLabels = ['Hoy', 'Semana', 'Mes', 'Todos'];

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUid;
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CTopBar(title: 'Mis pedidos', back: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: List.generate(_filterLabels.length, (i) {
                  final active = _filter == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? CourierColors.primary
                              : CourierColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: active
                              ? null
                              : Border.all(color: CourierColors.border),
                        ),
                        child: Text(
                          _filterLabels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? Colors.white
                                : CourierColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: uid == null
                  ? const _EmptyOrders(
                      title: 'Inicia sesión',
                      message: 'Para ver tus pedidos.',
                    )
                  : StreamBuilder<List<OrderModel>>(
                      stream: OrderService.streamForCourier(uid),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: CourierColors.primary),
                          );
                        }
                        final all = snap.data ?? const [];
                        final list = _filterOrders(all, _filter);
                        if (list.isEmpty) {
                          return const _EmptyOrders(
                            title: 'Aún no tienes pedidos',
                            message:
                                'Cuando completes entregas aparecerán aquí.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _OrderRow(order: list[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> all, int filter) {
    final now = DateTime.now();
    bool keep(OrderModel o) {
      switch (filter) {
        case 0:
          return _sameDay(o.createdAt, now);
        case 1:
          return now.difference(o.createdAt).inDays < 7;
        case 2:
          return now.difference(o.createdAt).inDays < 31;
        default:
          return true;
      }
    }

    return all.where(keep).toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == 'cancelado';
    final color = isCancelled ? CourierColors.danger : CourierColors.online;
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        '/order-detail',
        arguments: order,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CourierColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CourierColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: CourierColors.textSubtle,
                    ),
                  ),
                ),
                StatusPill(text: order.statusLabel.toUpperCase(), color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.storeName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: CourierColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              order.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: CourierColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: CourierColors.borderSoft, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_formatDate(order.createdAt)} · ${order.distanceKm != null ? '${order.distanceKm!.toStringAsFixed(1)} km' : '—'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CourierColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '+ S/ ${(isCancelled ? 0 : order.courierEarning).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isCancelled
                        ? CourierColors.textSubtle
                        : CourierColors.online,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Hoy · $hh:$mm';
    }
    return '${d.day}/${d.month} · $hh:$mm';
  }
}

class _EmptyOrders extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyOrders({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CourierColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: CourierColors.border),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: CourierColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: CourierColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CourierColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
