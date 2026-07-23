import 'dart:async';

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

  /// Offer instances already surfaced to this courier during the current online
  /// session, keyed by `orderId@assignmentExpiresAt`. Prevents the popup from
  /// firing twice for the SAME offer, while still re-showing the order when the
  /// round-robin re-offers it (a fresh `assignmentExpiresAt` ⇒ a new key) — this
  /// is what lets a lone active courier keep being re-offered every 30s.
  /// Reset only when the courier goes offline (see [_setOnline]).
  final Set<String> _shownOffers = {};

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
                // Decorative abstract backdrop only — it deliberately does NOT
                // claim to be the courier's real map, so no "you are here" dot
                // is drawn on it (the old fixed-position PulsingDot was fake).
                const DarkMapBackground(height: 460),
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
                          Flexible(
                            child: Text(
                              '${(courier?.rating ?? 5.0).toStringAsFixed(1)} · ${courier?.totalDeliveries ?? 0} entregas',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CourierColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _NotificationBell(uid: uid),
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
            busy: _toggling,
            onChanged: (v) => _setOnline(uid, v),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _DaySummarySheet(uid: uid),
        ),
        if (_online)
          _AvailableOrdersListener(
            courierId: uid,
            onOrders: (orders) {
              // Don't stack a second popup while one is already open.
              if (_newOrderShown) return;
              // Surface the first offer this courier hasn't already seen. Each
              // offer is keyed by its expiry so a re-offer (new window) re-shows
              // even for the same order — see [_shownOffers].
              OrderModel? next;
              String? nextKey;
              for (final o in orders) {
                final key = _offerKey(o);
                if (!_shownOffers.contains(key)) {
                  next = o;
                  nextKey = key;
                  break;
                }
              }
              if (next == null) return;
              _newOrderShown = true;
              _shownOffers.add(nextKey!);
              Navigator.of(context).pushNamed(
                '/new-order',
                arguments: next,
              ).then((_) => _newOrderShown = false);
            },
          ),
      ],
    );
  }

  /// Stable key for a single offer instance: the order plus the moment its
  /// current window expires. A fresh round-robin offer carries a new expiry, so
  /// it produces a new key and re-shows even for an order seen before.
  String _offerKey(OrderModel o) =>
      '${o.id}@${o.assignmentExpiresAt?.millisecondsSinceEpoch ?? 0}';

  Future<void> _setOnline(String uid, bool value) async {
    setState(() {
      _online = value;
      _toggling = true;
      // Going offline ends the session: clear the dedup guard so offers can be
      // re-shown next time the courier comes back online.
      if (!value) _shownOffers.clear();
    });
    try {
      await CourierService.setOnline(uid, value);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }
}

class _AvailableOrdersListener extends StatelessWidget {
  final String courierId;
  final void Function(List<OrderModel>) onOrders;

  const _AvailableOrdersListener({
    required this.courierId,
    required this.onOrders,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.streamOffersFor(courierId),
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

/// Bell that reflects the real `couriers/{uid}/notifications` feed: the badge
/// shows only when there are unread notices, and tapping opens a sheet with the
/// actual notifications (marking them read). No always-on fake badge.
class _NotificationBell extends StatelessWidget {
  final String uid;
  const _NotificationBell({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CourierNotice>>(
      stream: CourierService.streamNotices(uid),
      builder: (context, snap) {
        final notices = snap.data ?? const <CourierNotice>[];
        final unread = notices.where((n) => !n.read).length;
        return GestureDetector(
          onTap: () => _openSheet(context, notices),
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
                child: const Icon(Icons.notifications_none_rounded,
                    size: 20, color: CourierColors.text),
              ),
              if (unread > 0)
                Positioned(
                  top: 6,
                  right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 14),
                    height: 14,
                    decoration: BoxDecoration(
                      color: CourierColors.primary,
                      borderRadius: BorderRadius.circular(7),
                      border:
                          Border.all(color: CourierColors.surface, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context, List<CourierNotice> notices) {
    // Mark everything read on open (best-effort; failures are non-fatal).
    for (final n in notices.where((n) => !n.read)) {
      CourierService.markNoticeRead(uid, n.id).catchError((_) {});
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CourierColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              const Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CourierColors.text,
                ),
              ),
              const SizedBox(height: 12),
              if (notices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No tienes notificaciones.',
                    style: TextStyle(color: CourierColors.textMuted),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notices.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: CourierColors.borderSoft,
                      height: 20,
                    ),
                    itemBuilder: (_, i) {
                      final n = notices[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconBox(
                            icon: n.type == 'rejection'
                                ? Icons.cancel_outlined
                                : Icons.info_outline_rounded,
                            background: CourierColors.surface2,
                            color: n.type == 'rejection'
                                ? CourierColors.danger
                                : CourierColors.primary,
                            size: 38,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title.isEmpty ? 'Notificación' : n.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: CourierColors.text,
                                  ),
                                ),
                                if (n.body.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    n.body,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: CourierColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Online/offline toggle. Compact by design so it never overflows on narrow
/// (≤360dp) screens: no large decorative circle, the status text is wrapped in
/// a FittedBox, and the toggle/spinner has a fixed width. Green when online,
/// neutral (surface + border) when disconnected. While a toggle is in flight
/// ([busy]) the switch is disabled and shows a spinner for clear feedback.
class _OnlineSwitch extends StatelessWidget {
  final bool online;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _OnlineSwitch({
    required this.online,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = online ? CourierColors.onOnline : CourierColors.text;
    final mutedColor =
        online ? CourierColors.onOnline : CourierColors.textMuted;

    return GestureDetector(
      onTap: busy ? null : () => onChanged(!online),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: online ? CourierColors.online : CourierColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: online
              ? null
              : Border.all(color: CourierColors.border, width: 1),
          boxShadow: online
              ? [
                  BoxShadow(
                    color: CourierColors.online.withValues(alpha: 0.30),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Small status dot (informative, not the old bulky circle).
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? Colors.white : CourierColors.textSubtle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ESTÁS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: mutedColor,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // FittedBox guarantees the status word scales down instead of
                  // overflowing on very narrow screens.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      online ? 'EN LÍNEA' : 'DESCONECTADO',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: labelColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Toggle, or a spinner while the change is being written.
            SizedBox(
              width: 60,
              height: 34,
              child: busy
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: online
                              ? CourierColors.onOnline
                              : CourierColors.primary,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: online
                            ? CourierColors.onOnline
                            : CourierColors.surface2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 180),
                        alignment: online
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: online
                                ? Colors.white
                                : CourierColors.textSubtle,
                          ),
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

/// Live "today" summary. All three tiles are backed by real data:
/// - Pedidos / Ganancias: delivered orders for this courier dated today.
/// - En línea: accumulated online-time from `couriers/{uid}.onlineByDay` plus
///   the currently-open session, ticked every 30s so it advances live.
class _DaySummarySheet extends StatefulWidget {
  final String uid;
  const _DaySummarySheet({required this.uid});

  @override
  State<_DaySummarySheet> createState() => _DaySummarySheetState();
}

class _DaySummarySheetState extends State<_DaySummarySheet> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Advance the live online-time counter without touching Firestore.
    _tick = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool _isToday(DateTime d, DateTime now) =>
      d.year == now.year && d.month == now.month && d.day == now.day;

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
          StreamBuilder<List<OrderModel>>(
            stream: OrderService.streamForCourier(widget.uid),
            builder: (context, orderSnap) {
              final now = DateTime.now();
              final delivered = (orderSnap.data ?? const <OrderModel>[])
                  .where((o) =>
                      o.status == 'entregado' &&
                      _isToday(o.deliveredAt ?? o.createdAt, now))
                  .toList();
              final count = delivered.length;
              final earnings =
                  delivered.fold<double>(0, (s, o) => s + o.courierEarning);

              return StreamBuilder<CourierModel?>(
                stream: CourierService.streamCourier(widget.uid),
                builder: (context, courierSnap) {
                  final onlineSecs =
                      courierSnap.data?.onlineSecondsToday(DateTime.now()) ?? 0;
                  return Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          value: '$count',
                          label: 'Pedidos',
                          icon: Icons.shopping_bag_outlined,
                          color: CourierColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          value: 'S/ ${earnings.toStringAsFixed(0)}',
                          label: 'Ganancias',
                          icon: Icons.payments_outlined,
                          color: CourierColors.online,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          value: _formatDuration(onlineSecs),
                          label: 'En línea',
                          icon: Icons.access_time_rounded,
                          color: CourierColors.warning,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: CourierColors.text,
              ),
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
