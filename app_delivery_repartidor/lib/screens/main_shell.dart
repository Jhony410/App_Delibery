import 'dart:async';

import 'package:flutter/material.dart';
import '../models/courier_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/courier_service.dart';
import '../services/location_publisher_service.dart';
import '../services/order_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'orders_history_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    OrdersHistoryScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          // Invisible orchestrator: the single place that decides when the
          // courier's position is published. Lives here because MainShell stays
          // mounted for the whole session (the delivery workflow screens are
          // pushed on top of it), so start/stop never gets duplicated.
          const _DeliveryLocationController(),
        ],
      ),
      bottomNavigationBar: _CourierTabBar(
        active: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Orchestrates [LocationPublisherService]: publishes the courier position
/// only while they are online AND have an active order, and stops the instant
/// either condition drops (delivered / cancelled / offline). Renders nothing.
class _DeliveryLocationController extends StatefulWidget {
  const _DeliveryLocationController();

  @override
  State<_DeliveryLocationController> createState() =>
      _DeliveryLocationControllerState();
}

class _DeliveryLocationControllerState
    extends State<_DeliveryLocationController> {
  StreamSubscription<CourierModel?>? _courierSub;
  StreamSubscription<List<OrderModel>>? _ordersSub;
  bool _online = false;
  List<OrderModel> _orders = const [];
  // Guards the "customer won't see you" warning so it shows once per attempt,
  // not on every stream tick.
  bool _warned = false;

  static const _activeStatuses = {'accepted', 'picked_up', 'en_camino'};

  @override
  void initState() {
    super.initState();
    final uid = AuthService.currentUid;
    if (uid == null) return;
    _courierSub = CourierService.streamCourier(uid).listen((c) {
      _online = c?.online ?? false;
      _sync(uid);
    });
    // Single-field query (courierId) — filtered to active states client-side to
    // avoid needing a composite index.
    _ordersSub = OrderService.streamForCourier(uid).listen((o) {
      _orders = o;
      _sync(uid);
    });
  }

  void _sync(String uid) {
    final active =
        _orders.where((o) => _activeStatuses.contains(o.status)).toList();
    final shouldPublish = _online && active.isNotEmpty;
    if (shouldPublish) {
      LocationPublisherService.instance
          .start(uid: uid, orderId: active.first.id)
          .then(_handleStartResult);
    } else {
      LocationPublisherService.instance.stop();
      _warned = false;
    }
  }

  void _handleStartResult(PublishStartResult r) {
    final msg = r.warning;
    if (msg != null && !_warned && mounted) {
      _warned = true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: CourierColors.warning,
      ));
    }
  }

  @override
  void dispose() {
    _courierSub?.cancel();
    _ordersSub?.cancel();
    // MainShell only unmounts on logout / app teardown — stop cleanly then.
    LocationPublisherService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _CourierTabBar extends StatelessWidget {
  final int active;
  final ValueChanged<int> onTap;

  const _CourierTabBar({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Inicio', Icons.home_outlined, Icons.home_rounded),
      ('Pedidos', Icons.list_alt_outlined, Icons.list_alt_rounded),
      ('Billetera', Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet_rounded),
      ('Perfil', Icons.person_outline_rounded, Icons.person_rounded),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: CourierColors.surface,
        border: Border(
          top: BorderSide(color: CourierColors.border, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: 18 + MediaQuery.of(context).padding.bottom * 0.4,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = i == active;
          final (label, off, on) = tabs[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? on : off,
                    size: 26,
                    color: isActive
                        ? CourierColors.primary
                        : CourierColors.textSubtle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? CourierColors.primary
                          : CourierColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
