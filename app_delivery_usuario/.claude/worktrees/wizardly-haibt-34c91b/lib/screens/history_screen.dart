import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../models/order_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filter = 0;
  static const _filters = ['Todos', 'Activos', 'Entregados'];

  List<OrderModel> _applyFilter(List<OrderModel> orders) {
    if (_filter == 1) {
      return orders
          .where((o) => o.status == 'en_camino' || o.status == 'confirmed' || o.status == 'preparing')
          .toList();
    }
    if (_filter == 2) return orders.where((o) => o.status == 'entregado').toList();
    return orders;
  }

  Color _statusColor(String status) {
    if (status == 'entregado') return AppColors.secondary;
    if (status == 'cancelado') return AppColors.danger;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUid;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: top + 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Mis pedidos',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.34)),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.tune, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: _filters.asMap().entries.map((e) {
                final sel = e.key == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.appText : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: sel ? Colors.transparent : AppColors.border,
                      ),
                    ),
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : AppColors.textMuted)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: uid == null
                ? const Center(
                    child: Text('Inicia sesión para ver tus pedidos',
                        style: TextStyle(color: AppColors.textMuted)))
                : StreamBuilder<List<OrderModel>>(
                    stream: DbService.streamUserOrders(uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }
                      final all = snap.data ?? [];
                      final orders = _applyFilter(all);
                      if (orders.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 64, color: AppColors.border),
                              SizedBox(height: 16),
                              Text('Sin pedidos aún',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: orders.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          final statusColor = _statusColor(o.status);
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, '/tracking',
                                arguments: o.id),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  ImgPlaceholder(
                                      height: 56,
                                      width: 56,
                                      tone: o.storeTone,
                                      radius: 12),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(o.storeName,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Text(
                                                _formatDate(o.createdAt),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSubtle,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                            '${o.items.length} producto${o.items.length != 1 ? 's' : ''} · ${o.items.map((e) => e.name).take(2).join(', ')}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                                height: 1.35)),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(o.statusLabel,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: statusColor)),
                                            ),
                                            Text(
                                                'S/ ${o.total.toStringAsFixed(2)}',
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
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Hoy · ${_time(dt)}';
    if (diff.inDays == 1) return 'Ayer · ${_time(dt)}';
    return '${dt.day} ${_month(dt.month)} · ${_time(dt)}';
  }

  String _time(DateTime dt) =>
      '${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';

  String _month(int m) => ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'][m - 1];
}
