import 'package:flutter/material.dart';
import '../models/courier_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/courier_service.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

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
            const CTopBar(title: 'Billetera', back: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: uid == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<CourierModel?>(
                            stream: CourierService.streamCourier(uid),
                            builder: (_, snap) {
                              final balance = snap.data?.totalEarnings ?? 0;
                              return _BalanceCard(balance: balance);
                            },
                          ),
                          const SizedBox(height: 16),
                          _WeekSummary(uid: uid),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Historial de ingresos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: CourierColors.text,
                                ),
                              ),
                              Text(
                                'Por día ▾',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CourierColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _DailyHistory(uid: uid),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CourierColors.primary, Color(0xFFFF8F5B)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SALDO DISPONIBLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'S/ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -2,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Próximo retiro automático: viernes',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Retirar a mi cuenta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekSummary extends StatelessWidget {
  final String uid;
  const _WeekSummary({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.streamForCourier(uid),
      builder: (_, snap) {
        final all = snap.data ?? const [];
        final now = DateTime.now();
        final week = all.where((o) =>
            o.status == 'entregado' &&
            now.difference(o.createdAt).inDays < 7);
        final total =
            week.fold<double>(0, (s, o) => s + o.courierEarning);
        final count = week.length;
        final avg = count == 0 ? 0 : total / count;
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'ESTA SEMANA',
                value: 'S/ ${total.toStringAsFixed(2)}',
                hint: count > 0 ? 'Activo' : 'Sin entregas',
                hintColor: count > 0 ? CourierColors.online : CourierColors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'PEDIDOS',
                value: count.toString(),
                hint: count == 0 ? '—' : '~ S/ ${avg.toStringAsFixed(2)} c/u',
                hintColor: CourierColors.textMuted,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color hintColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourierColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourierColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CourierColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: CourierColors.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11,
              color: hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyHistory extends StatelessWidget {
  final String uid;
  const _DailyHistory({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.streamForCourier(uid),
      builder: (_, snap) {
        final all = (snap.data ?? const [])
            .where((o) => o.status == 'entregado')
            .toList();
        if (all.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CourierColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CourierColors.border),
            ),
            child: const Text(
              'Aún no hay ingresos para mostrar.',
              style: TextStyle(color: CourierColors.textMuted),
            ),
          );
        }
        final byDay = <String, _DayBucket>{};
        for (final o in all) {
          final key =
              '${o.createdAt.year}-${o.createdAt.month}-${o.createdAt.day}';
          byDay.putIfAbsent(
            key,
            () => _DayBucket(day: DateTime(o.createdAt.year,
                o.createdAt.month, o.createdAt.day)),
          );
          final b = byDay[key]!;
          b.orders++;
          b.total += o.courierEarning;
        }
        final list = byDay.values.toList()
          ..sort((a, b) => b.day.compareTo(a.day));
        return Container(
          decoration: BoxDecoration(
            color: CourierColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CourierColors.border),
          ),
          child: Column(
            children: list.asMap().entries.map((e) {
              final last = e.key == list.length - 1;
              final b = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDay(b.day),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CourierColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b.orders} pedidos',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CourierColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'S/ ${b.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: e.key == 0
                            ? CourierColors.online
                            : CourierColors.text,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatDay(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Hoy · ${d.day}/${d.month}';
    }
    if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day - 1) {
      return 'Ayer · ${d.day}/${d.month}';
    }
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _DayBucket {
  final DateTime day;
  int orders;
  double total;
  _DayBucket({required this.day})
      : orders = 0,
        total = 0;
}
