import 'package:flutter/material.dart';
import '../models/courier_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/courier_service.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// How the income history is grouped. Driven by the (now functional) selector.
enum _GroupBy { day, week, month }

extension on _GroupBy {
  String get label => switch (this) {
        _GroupBy.day => 'Por día',
        _GroupBy.week => 'Por semana',
        _GroupBy.month => 'Por mes',
      };
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  _GroupBy _group = _GroupBy.day;

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
                            builder: (_, snap) =>
                                _BalanceCard(courier: snap.data),
                          ),
                          const SizedBox(height: 16),
                          _WeekSummary(uid: uid),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Historial de ingresos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: CourierColors.text,
                                ),
                              ),
                              _GroupSelector(
                                current: _group,
                                onChanged: (g) => setState(() => _group = g),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _History(uid: uid, group: _group),
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

class _GroupSelector extends StatelessWidget {
  final _GroupBy current;
  final ValueChanged<_GroupBy> onChanged;

  const _GroupSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_GroupBy>(
      initialValue: current,
      color: CourierColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CourierColors.border),
      ),
      onSelected: onChanged,
      itemBuilder: (_) => _GroupBy.values
          .map((g) => PopupMenuItem<_GroupBy>(
                value: g,
                child: Text(
                  g.label,
                  style: TextStyle(
                    color: g == current
                        ? CourierColors.primary
                        : CourierColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            current.label,
            style: const TextStyle(
              fontSize: 12,
              color: CourierColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(Icons.arrow_drop_down,
              size: 18, color: CourierColors.primary),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final CourierModel? courier;
  const _BalanceCard({required this.courier});

  String _maskAccount(String acc) {
    final trimmed = acc.trim();
    if (trimmed.length <= 4) return trimmed;
    return '•••• ${trimmed.substring(trimmed.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final balance = courier?.totalEarnings ?? 0;
    final account = courier?.bankAccount ?? '';
    final hasAccount = account.trim().isNotEmpty;

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
            'SALDO ACUMULADO',
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
          // Real info instead of the old invented "retiro automático: viernes".
          Text(
            hasAccount
                ? 'Cuenta registrada: ${_maskAccount(account)}'
                : 'Aún no registras una cuenta bancaria',
            style: const TextStyle(
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
                onTap: () => _showWithdrawInfo(context, account),
                borderRadius: BorderRadius.circular(12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 20, color: Colors.white),
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

  void _showWithdrawInfo(BuildContext context, String account) {
    final hasAccount = account.trim().isNotEmpty;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CourierColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Retiro de ganancias',
          style: TextStyle(
            color: CourierColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Los retiros se gestionan manualmente por el equipo de DeliPuno '
              'y se depositan a la cuenta bancaria que tengas registrada.',
              style: TextStyle(color: CourierColors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CourierColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_outlined,
                      size: 20, color: CourierColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasAccount
                          ? account
                          : 'Sin cuenta bancaria registrada. Agrégala en Perfil › Cuenta bancaria.',
                      style: const TextStyle(
                        color: CourierColors.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: CourierColors.primary,
                fontWeight: FontWeight.w800,
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
            now.difference(o.deliveredAt ?? o.createdAt).inDays < 7);
        final total = week.fold<double>(0, (s, o) => s + o.courierEarning);
        final count = week.length;
        final avg = count == 0 ? 0 : total / count;
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'ESTA SEMANA',
                value: 'S/ ${total.toStringAsFixed(2)}',
                hint: count > 0 ? 'Activo' : 'Sin entregas',
                hintColor:
                    count > 0 ? CourierColors.online : CourierColors.textMuted,
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

class _History extends StatelessWidget {
  final String uid;
  final _GroupBy group;
  const _History({required this.uid, required this.group});

  DateTime _dateOf(OrderModel o) => o.deliveredAt ?? o.createdAt;

  /// Bucket start date for the active grouping (used both as sort key and label).
  DateTime _bucketStart(DateTime d) {
    switch (group) {
      case _GroupBy.day:
        return DateTime(d.year, d.month, d.day);
      case _GroupBy.week:
        final monday = d.subtract(Duration(days: d.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case _GroupBy.month:
        return DateTime(d.year, d.month);
    }
  }

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
        final byBucket = <DateTime, _Bucket>{};
        for (final o in all) {
          final key = _bucketStart(_dateOf(o));
          final b = byBucket.putIfAbsent(key, () => _Bucket(start: key));
          b.orders++;
          b.total += o.courierEarning;
        }
        final list = byBucket.values.toList()
          ..sort((a, b) => b.start.compareTo(a.start));
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          last ? Colors.transparent : CourierColors.borderSoft,
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
                            _label(b.start),
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

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _label(DateTime d) {
    final now = DateTime.now();
    switch (group) {
      case _GroupBy.day:
        if (d.year == now.year && d.month == now.month && d.day == now.day) {
          return 'Hoy · ${d.day}/${d.month}';
        }
        final yest = now.subtract(const Duration(days: 1));
        if (d.year == yest.year &&
            d.month == yest.month &&
            d.day == yest.day) {
          return 'Ayer · ${d.day}/${d.month}';
        }
        return '${d.day}/${d.month}/${d.year}';
      case _GroupBy.week:
        final end = d.add(const Duration(days: 6));
        return 'Semana ${d.day} ${_months[d.month - 1]} – '
            '${end.day} ${_months[end.month - 1]}';
      case _GroupBy.month:
        return '${_months[d.month - 1]} ${d.year}';
    }
  }
}

class _Bucket {
  final DateTime start;
  int orders;
  double total;
  _Bucket({required this.start})
      : orders = 0,
        total = 0;
}
