import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/external_maps.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/courier_map.dart';

class RouteToCustomerScreen extends StatelessWidget {
  final OrderModel order;
  const RouteToCustomerScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // No customer coordinates on OrderModel yet — show only the courier's live
    // position. Pass `destination` here once lat/lng propagate from the client.
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CourierMap(
              destinationLabel: order.customerName ?? 'Cliente',
              loadingLabel: 'Buscando ruta al cliente',
            ),
          ),
          // Top-anchored, content-height header floating over the map.
          // Positioned(top/left/right) with no bottom means it takes only its
          // content height and can never stretch to fill the Stack.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: CourierColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CourierColors.border),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 24, color: CourierColors.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: CourierColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CourierColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: CourierColors.online,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              size: 22,
                              color: CourierColors.onOnline,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ENTREGAR A',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CourierColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.customerName ?? 'Cliente',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: CourierColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: CourierColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: CourierColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
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
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: CourierColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(order.customerName ?? 'Cliente'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: CourierColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName ?? 'Cliente',
                                style: const TextStyle(
                                  fontSize: 17,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed(
                            '/chat',
                            arguments: order,
                          ),
                          child: const IconBox(
                            icon: Icons.chat_bubble_outline,
                            background: CourierColors.surface2,
                            color: CourierColors.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const IconBox(
                          icon: Icons.phone_rounded,
                          background: CourierColors.online,
                          color: CourierColors.onOnline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Real turn-by-turn is delegated to the phone's Google Maps
                    // (no in-app Directions API). Opens a search for the address.
                    CButton(
                      label: 'Abrir en Google Maps',
                      icon: Icons.map_outlined,
                      size: CButtonSize.lg,
                      variant: CButtonVariant.ghost,
                      onPressed: () => _openMaps(context),
                    ),
                    const SizedBox(height: 10),
                    CButton(
                      label: 'Llegué al cliente',
                      icon: Icons.check_circle_outline,
                      size: CButtonSize.xl,
                      variant: CButtonVariant.online,
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed(
                        '/deliver',
                        arguments: order,
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

  Future<void> _openMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final query = order.address.trim().isNotEmpty
        ? order.address
        : (order.customerName ?? '');
    final ok = await ExternalMaps.open(query: query);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No se pudo abrir Google Maps.'),
        backgroundColor: CourierColors.danger,
      ));
    }
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
