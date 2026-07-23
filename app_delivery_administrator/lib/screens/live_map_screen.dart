import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../models/courier_model.dart';
import '../models/order_model.dart';
import '../models/store_model.dart';
import '../routes.dart';
import '../services/courier_location_service.dart';
import '../services/courier_service.dart';
import '../services/order_service.dart';
import '../services/store_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/map_location_picker.dart';

/// Live map. Plots the STORES that have coordinates AND the real couriers that
/// are publishing their position to `courierLocations` (written by the courier
/// app while it has an active delivery). Couriers whose last update is older
/// than 10 minutes are treated as disconnected and are not shown as live.
class LiveMapScreen extends StatelessWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'mapa',
      title: 'Mapa en vivo',
      child: StreamBuilder<List<StoreModel>>(
        stream: StoreService.getStoresStream(),
        builder: (context, storeSnap) {
          final stores = storeSnap.data ?? const <StoreModel>[];
          final located = stores
              .where((s) => s.latitude != null && s.longitude != null)
              .toList();
          final withoutLocation = stores.length - located.length;

          return StreamBuilder<List<CourierLocationDoc>>(
            stream: CourierLocationService.streamAll(),
            builder: (context, locSnap) {
              final now = DateTime.now();
              final all = locSnap.data ?? const <CourierLocationDoc>[];
              final fresh = all.where((c) => c.isFresh(now)).toList();
              final disconnected = all.length - fresh.length;
              // Real "last data received" time — the newest updatedAt across all
              // published positions (no simulated clock).
              DateTime? lastUpdate;
              for (final c in all) {
                final u = c.updatedAt;
                if (u != null &&
                    (lastUpdate == null || u.isAfter(lastUpdate))) {
                  lastUpdate = u;
                }
              }

              return StreamBuilder<List<CourierModel>>(
                stream: CourierService.streamAll(),
                builder: (context, courierSnap) {
                  final names = <String, String>{
                    for (final c
                        in courierSnap.data ?? const <CourierModel>[])
                      c.uid: c.name,
                  };
                  return _LiveMapLayout(
                    located: located,
                    withoutLocation: withoutLocation,
                    couriers: fresh,
                    disconnected: disconnected,
                    courierNames: names,
                    lastUpdate: lastUpdate,
                    loadingStores: !storeSnap.hasData,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LiveMapLayout extends StatelessWidget {
  final List<StoreModel> located;
  final int withoutLocation;
  final List<CourierLocationDoc> couriers;
  final int disconnected;
  final Map<String, String> courierNames;
  final DateTime? lastUpdate;
  final bool loadingStores;
  const _LiveMapLayout({
    required this.located,
    required this.withoutLocation,
    required this.couriers,
    required this.disconnected,
    required this.courierNames,
    required this.lastUpdate,
    required this.loadingStores,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final twoCol = c.maxWidth > 1100;
      final map = SizedBox(
        height: 760,
        child: AdminCard.flush(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _LiveMap(
                    stores: located,
                    couriers: couriers,
                    courierNames: courierNames,
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _MapLegend(
                    storeCount: located.length,
                    courierCount: couriers.length,
                    disconnected: disconnected,
                    lastUpdate: lastUpdate,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final right = SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _InProgressOrders(),
            const SizedBox(height: 12),
            _StoresCoverageCard(
              located: located.length,
              missing: withoutLocation,
              loading: loadingStores,
            ),
          ],
        ),
      );
      if (!twoCol) {
        return Column(children: [map, const SizedBox(height: 16), right]);
      }
      return SizedBox(
        height: 760,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: map),
            const SizedBox(width: 16),
            right,
          ],
        ),
      );
    });
  }
}

/// Real Google Map: one orange marker per located store, one azure marker per
/// live courier. Tapping a courier marker shows their name and current order.
class _LiveMap extends StatelessWidget {
  final List<StoreModel> stores;
  final List<CourierLocationDoc> couriers;
  final Map<String, String> courierNames;
  const _LiveMap({
    required this.stores,
    required this.couriers,
    required this.courierNames,
  });

  static String _shortId(String id) => id.length > 6 ? id.substring(0, 6) : id;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      for (final s in stores)
        Marker(
          markerId: MarkerId('store_${s.id}'),
          position: LatLng(s.latitude!, s.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: s.name,
            snippet: s.category.isEmpty ? 'Comercio' : s.category,
          ),
        ),
      for (final c in couriers)
        Marker(
          markerId: MarkerId('courier_${c.courierId}'),
          position: LatLng(c.lat, c.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: courierNames[c.courierId] ?? 'Repartidor',
            snippet: c.activeOrderId != null
                ? 'Lleva el pedido #${_shortId(c.activeOrderId!)}'
                : 'Sin pedido activo',
          ),
        ),
    };
    // Center on a live courier first, else a store, else Puno. Only affects the
    // initial camera — later data updates never yank the admin's view.
    final center = couriers.isNotEmpty
        ? LatLng(couriers.first.lat, couriers.first.lng)
        : (stores.isNotEmpty
            ? LatLng(stores.first.latitude!, stores.first.longitude!)
            : kPunoCenter);
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: (couriers.isEmpty && stores.isEmpty) ? kPunoZoom : 13,
      ),
      markers: markers,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
    );
  }
}

class _MapLegend extends StatelessWidget {
  final int storeCount;
  final int courierCount;
  final int disconnected;
  final DateTime? lastUpdate;
  const _MapLegend({
    required this.storeCount,
    required this.courierCount,
    required this.disconnected,
    required this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('EN EL MAPA',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AdminColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.storefront,
                  size: 15, color: AdminColors.primary),
              const SizedBox(width: 6),
              Text('$storeCount comercios',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.two_wheeler,
                  size: 15, color: AdminColors.blue),
              const SizedBox(width: 6),
              Text(
                  courierCount > 0
                      ? '$courierCount repartidor(es) en vivo'
                      : 'Sin repartidores en vivo',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
          if (disconnected > 0) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 220,
              child: Text(
                '$disconnected repartidor(es) desconectado(s) '
                '(sin señal hace más de 10 min).',
                style: const TextStyle(
                    fontSize: 10.5, color: AdminColors.textSubtle),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            lastUpdate != null
                ? 'Último dato ${DateFormat('h:mm:ss a').format(lastUpdate!)}'
                : 'Sin datos de repartidores todavía',
            style: const TextStyle(
                fontSize: 10.5, color: AdminColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Real active-orders list (replaces the old hardcoded rows).
class _InProgressOrders extends StatelessWidget {
  const _InProgressOrders();

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pedidos en curso',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<List<OrderModel>>(
            stream: OrderService.streamActive(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final orders = snap.data!;
              if (orders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No hay pedidos en curso.',
                      style: TextStyle(
                          fontSize: 12.5, color: AdminColors.textMuted)),
                );
              }
              final shown = orders.take(8).toList();
              return Column(
                children: [
                  for (int i = 0; i < shown.length; i++) ...[
                    InkWell(
                      onTap: () => Navigator.pushNamed(
                          context, AdminRoutes.orderDetail,
                          arguments: shown[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 78,
                              child: Text(
                                shown[i].id.length > 6
                                    ? '#${shown[i].id.substring(0, 6)}'
                                    : '#${shown[i].id}',
                                style: GoogleFonts.robotoMono(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                shown[i].customerName ??
                                    shown[i].storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AdminColors.textMuted),
                              ),
                            ),
                            AdminBadge(shown[i].statusLabel,
                                tone: shown[i].statusTone),
                          ],
                        ),
                      ),
                    ),
                    if (i < shown.length - 1)
                      const Divider(height: 1, color: AdminColors.border),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Replaces the old invented "zone heatmap". There is no zones system with real
/// data, so instead we surface a real, actionable figure: how many stores still
/// lack coordinates (they won't appear on the map until an admin sets them).
class _StoresCoverageCard extends StatelessWidget {
  final int located;
  final int missing;
  final bool loading;
  const _StoresCoverageCard({
    required this.located,
    required this.missing,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cobertura de comercios',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            _row(AdminColors.green, 'Con ubicación', '$located'),
            const SizedBox(height: 8),
            _row(AdminColors.amber, 'Sin ubicación', '$missing'),
            if (missing > 0) ...[
              const SizedBox(height: 10),
              Text(
                '$missing comercio(s) no aparecen en el mapa hasta definir su '
                'ubicación en la ficha del comercio.',
                style: const TextStyle(
                    fontSize: 11, color: AdminColors.textMuted),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(Color color, String label, String value) {
    return Row(
      children: [
        AdminStatusDot(color: color, label: label),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12.5)),
      ],
    );
  }
}
