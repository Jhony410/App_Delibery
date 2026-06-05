import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets.dart';

class NewOrderScreen extends StatefulWidget {
  final OrderModel order;
  const NewOrderScreen({super.key, required this.order});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen>
    with SingleTickerProviderStateMixin {
  static const _windowSeconds = 15;
  late int _secondsLeft;
  Timer? _timer;
  StreamSubscription<OrderModel?>? _statusSub;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _windowSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        Navigator.of(context).maybePop();
      }
    });

    // Auto-dismiss: watch this order's document. If its status leaves the
    // available window (another courier accepted it, or it was cancelled /
    // deleted), close the popup so we don't show a stale offer.
    _statusSub = OrderService.streamOrder(widget.order.id).listen((order) {
      if (!mounted || _accepting) return;
      final status = order?.status;
      if (status != 'confirmed' && status != 'preparing') {
        _timer?.cancel();
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _cancelListeners();
    super.dispose();
  }

  /// Stop the countdown and the order-status watcher. Idempotent — safe to call
  /// from a dismissal path and again from [dispose].
  void _cancelListeners() {
    _timer?.cancel();
    _statusSub?.cancel();
  }

  Future<void> _accept() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    setState(() => _accepting = true);
    _cancelListeners();
    try {
      final ok = await OrderService.acceptOrder(widget.order.id, uid);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacementNamed(
          '/order-detail',
          arguments: widget.order,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Otro repartidor tomó el pedido.'),
            backgroundColor: CourierColors.surface2,
          ),
        );
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  void _reject() async {
    // Cancel timer + status watcher up front, before the async write, so
    // neither can fire during the gap or after the popup is gone.
    _cancelListeners();
    // Increment rejectedCount only — status is left untouched so the order
    // stays available for other couriers.
    await OrderService.rejectOrder(widget.order.id);
    // Return the id so HomeScreen pins it in _shownOrderIds and never
    // re-offers it to this courier for the rest of the session.
    if (mounted) Navigator.of(context).maybePop(widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final progress = _secondsLeft / _windowSeconds;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
              decoration: const BoxDecoration(
                color: CourierColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(
                              value: progress.clamp(0, 1),
                              strokeWidth: 6,
                              backgroundColor: CourierColors.surface2,
                              color: CourierColors.primary,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${_secondsLeft}s',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: CourierColors.text,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'NUEVO PEDIDO DISPONIBLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CourierColors.primary,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'S/ ${order.courierEarning.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: CourierColors.text,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const Text(
                      'Pago estimado',
                      style: TextStyle(
                        fontSize: 12,
                        color: CourierColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _RoutePreview(order: order),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CButton(
                            label: 'Rechazar',
                            variant: CButtonVariant.ghost,
                            size: CButtonSize.xl,
                            onPressed: _accepting ? null : _reject,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: CButton(
                            label: _accepting ? 'Aceptando…' : 'Aceptar',
                            size: CButtonSize.xl,
                            onPressed: _accepting ? null : _accept,
                          ),
                        ),
                      ],
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

class _RoutePreview extends StatelessWidget {
  final OrderModel order;
  const _RoutePreview({required this.order});

  @override
  Widget build(BuildContext context) {
    final dist = order.distanceKm ?? 4.3;
    final eta = (dist * 4).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CourierColors.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _RouteRow(
            icon: Icons.shopping_bag_outlined,
            iconBg: CourierColors.primaryTint,
            iconColor: CourierColors.primary,
            title: 'Recoger en ${order.storeName}',
            subtitle: order.storeAddress ?? 'Comercio',
          ),
          Container(
            margin: const EdgeInsets.only(left: 17, top: 6, bottom: 6),
            height: 18,
            child: const VerticalDivider(
              color: CourierColors.border,
              thickness: 1,
              width: 2,
            ),
          ),
          _RouteRow(
            icon: Icons.location_on_outlined,
            iconBg: CourierColors.onlineTint,
            iconColor: CourierColors.online,
            title: 'Entregar al cliente',
            subtitle: order.address,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Distancia total',
                  value: '${dist.toStringAsFixed(1)} km',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Tiempo estimado',
                  value: '~ $eta min',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _RouteRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBox(
          icon: icon,
          background: iconBg,
          color: iconColor,
          size: 36,
          iconSize: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CourierColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: CourierColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CourierColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CourierColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CourierColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
