import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/external_maps.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/courier_map.dart';

class RouteToStoreScreen extends StatelessWidget {
  final OrderModel order;
  const RouteToStoreScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // OrderModel carries no store coordinates today, so we can only show the
    // courier's live position. When storeLat/storeLng are added upstream, pass
    // them here as `destination` and the marker + camera framing appear for free.
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CourierMap(
              destinationLabel: order.storeName,
              loadingLabel: 'Buscando ruta al comercio',
            ),
          ),
          // Top-anchored, content-height header floating over the map. Using
          // Positioned(top/left/right) with no bottom guarantees it only takes
          // the height of its content — it can never stretch to fill the Stack.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: _DestinationHeader(
                  title: 'RECOGER EN',
                  name: order.storeName,
                  address: order.storeAddress ?? 'Dirección no registrada',
                  iconBg: CourierColors.primary,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomSheet(
              title: 'RECOGER EN',
              storeName: order.storeName,
              address: order.storeAddress ?? 'Dirección no registrada',
              mapsQuery: order.storeAddress ?? order.storeName,
              cta: 'Llegué al comercio',
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                '/pickup',
                arguments: order,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationHeader extends StatelessWidget {
  final String title;
  final String name;
  final String address;
  final Color iconBg;
  final VoidCallback onBack;

  const _DestinationHeader({
    required this.title,
    required this.name,
    required this.address,
    required this.iconBg,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront_rounded,
                      size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CourierColors.textMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
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
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final String title;
  final String storeName;
  final String address;
  final String mapsQuery;
  final String cta;
  final VoidCallback onPressed;

  const _BottomSheet({
    required this.title,
    required this.storeName,
    required this.address,
    required this.mapsQuery,
    required this.cta,
    required this.onPressed,
  });

  Future<void> _openMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ExternalMaps.open(query: mapsQuery);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No se pudo abrir Google Maps.'),
        backgroundColor: CourierColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Real destination info only — no fabricated distance/ETA. There are
            // no destination coordinates on OrderModel yet, so straight-line
            // distance (Geolocator.distanceBetween) cannot be computed; we omit
            // it rather than show an invented value.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CourierColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: CourierColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CourierColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Real turn-by-turn navigation is delegated to the phone's Google
            // Maps (no in-app Directions API). Opens a search for the address.
            CButton(
              label: 'Abrir en Google Maps',
              icon: Icons.map_outlined,
              size: CButtonSize.lg,
              variant: CButtonVariant.ghost,
              onPressed: () => _openMaps(context),
            ),
            const SizedBox(height: 10),
            CButton(
              label: cta,
              icon: Icons.check_circle_outline,
              size: CButtonSize.xl,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
