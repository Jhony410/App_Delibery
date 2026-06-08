import 'package:flutter/material.dart';
import '../models/courier_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/courier_service.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _online = false;
  bool _toggling = false;
  bool _newOrderShown = false;

  /// Order IDs already surfaced to this courier during the current online
  /// session. Prevents the popup from firing twice for the same order — e.g.
  /// after a reject or timeout, when the order is still in `streamAvailable()`.
  /// Reset only when the courier goes offline (see [_setOnline]).
  final Set<String> _shownOrderIds = {};

  String? get _uid => AuthService.currentUid;

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Center(child: Text('No has iniciado sesión.'));
    }

    return StreamBuilder<CourierModel?>(
      stream: CourierService.streamCourier(uid),
      builder: (context, snap) {
        final courier = snap.data;
        if (courier != null && courier.online != _online && !_toggling) {
          _online = courier.online;
        }
        return _buildHome(courier, uid);
      },
    );
  }

  Widget _buildHome(CourierModel? courier, String uid) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 460,
          child: ClipRect(
            child: Stack(
              children: [
                const DarkMapBackground(height: 460),
                if (_online)
                  const Positioned(
                    left: 175,
                    top: 200,
                    child: PulsingDot(),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          CourierColors.bg.withValues(alpha: 0.4),
                          CourierColors.bg.withValues(alpha: 0),
                          CourierColors.bg.withValues(alpha: 0),
                          CourierColors.bg,
                        ],
                        stops: const [0, 0.3, 0.6, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Row(
              children: [
                _Avatar(initials: courier?.initials ?? 'R'),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola ${courier?.name.split(' ').first ?? ''}!',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CourierColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: CourierColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${(courier?.rating ?? 5.0).toStringAsFixed(1)} · ${courier?.totalDeliveries ?? 0} entregas',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CourierColors.text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _CircleButton(
                  icon: Icons.notifications_none_rounded,
                  hasBadge: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 280,
          left: 20,
          right: 20,
          child: _OnlineSwitch(
            online: _online,
            onChanged: (v) => _setOnline(uid, v),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: const _DaySummarySheet(),
        ),
        if (_online)
          _AvailableOrdersListener(
            onOrders: (orders) {
              // Don't stack a second popup while one is already open.
              if (_newOrderShown) return;
              // Surface the first available order this courier hasn't already
              // seen this session (rejected/expired ones are pinned below).
              OrderModel? next;
              for (final o in orders) {
                if (!_shownOrderIds.contains(o.id)) {
                  next = o;
                  break;
                }
              }
              if (next == null) return;
              _newOrderShown = true;
              _shownOrderIds.add(next.id);
              Navigator.of(context).pushNamed(
                '/new-order',
                arguments: next,
              ).then((result) {
                _newOrderShown = false;
                // Rechazar/timeout pops with the orderId — pin it so it's not
                // re-shown to this courier for the rest of the session.
                if (result is String) _shownOrderIds.add(result);
              });
            },
          ),
      ],
    );
  }

  Future<void> _setOnline(String uid, bool value) async {
    setState(() {
      _online = value;
      _toggling = true;
      // Going offline ends the session: clear the dedup guard so orders can be
      // re-offered next time the courier comes back online.
      if (!value) _shownOrderIds.clear();
    });
    try {
      await CourierService.setOnline(uid, value);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }
}

class _AvailableOrdersListener extends StatelessWidget {
  final void Function(List<OrderModel>) onOrders;

  const _AvailableOrdersListener({required this.onOrders});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.streamAvailable(),
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Only surface the popup while Home is the topmost route, so we
            // never stack it over the order-detail / workflow screens.
            if (ModalRoute.of(context)?.isCurrent ?? false) {
              onOrders(list);
            }
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CourierColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: CourierColors.text,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    this.hasBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CourierColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CourierColors.border),
            ),
            child: Icon(icon, size: 20, color: CourierColors.text),
          ),
          if (hasBadge)
            Positioned(
              top: 8,
              right: 9,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CourierColors.primary,
                  border: Border.all(color: CourierColors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnlineSwitch extends StatelessWidget {
  final bool online;
  final ValueChanged<bool> onChanged;

  const _OnlineSwitch({required this.online, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!online),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: BoxDecoration(
          color: online ? CourierColors.online : CourierColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: online
              ? null
              : Border.all(color: CourierColors.border, width: 1),
          boxShadow: online
              ? [
                  BoxShadow(
                    color: CourierColors.online.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online
                    ? Colors.black.withValues(alpha: 0.18)
                    : CourierColors.surface2,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? Colors.white : CourierColors.textSubtle,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ESTÁS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: online ? CourierColors.onOnline : CourierColors.textMuted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  Text(
                    online ? 'EN LÍNEA' : 'DESCONECTADO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: online ? CourierColors.onOnline : CourierColors.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: online
                    ? CourierColors.onOnline
                    : CourierColors.surface2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: online ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online ? Colors.white : CourierColors.textSubtle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySummarySheet extends StatelessWidget {
  const _DaySummarySheet();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Container(
      decoration: const BoxDecoration(
        color: CourierColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: CourierColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: CourierColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'RESUMEN DE HOY · ${_formatDay(today)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CourierColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  value: '0',
                  label: 'Pedidos',
                  icon: Icons.shopping_bag_outlined,
                  color: CourierColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  value: 'S/ 0',
                  label: 'Ganancias',
                  icon: Icons.payments_outlined,
                  color: CourierColors.online,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  value: '0h 00m',
                  label: 'En línea',
                  icon: Icons.access_time_rounded,
                  color: CourierColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDay(DateTime d) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1].toUpperCase()}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourierColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: CourierColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CourierColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
