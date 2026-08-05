import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme.dart';
import '../models/order_model.dart';
import '../services/db_service.dart';
import '../widgets.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const _steps = ['Recibido', 'Preparando', 'En camino', 'Entregado'];

  String? _orderId;
  Stream<OrderModel?>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id != null && id != _orderId) {
      _orderId = id;
      _stream = DbService.streamOrder(id);
    }
  }

  // Maps the shared order status (which the courier app also writes) onto the
  // 4 visual steps: Recibido · Preparando · En camino · Entregado.
  int _activeStep(String status) => switch (status) {
    'confirmed' => 0,
    'preparing' => 1,
    'accepted' => 1, // courier assigned, food still being prepared
    'picked_up' => 2, // courier has the order, heading out
    'en_camino' => 2,
    'entregado' => 3,
    _ => 0,
  };

  String _etaLabel(String status) => switch (status) {
    'confirmed' => 'Pedido recibido',
    'preparing' => 'Preparando tu pedido',
    'accepted' => 'Repartidor asignado',
    'picked_up' => 'Pedido recogido',
    'en_camino' => 'Tu pedido está en camino',
    'entregado' => '¡Entregado!',
    'cancelado' => 'Pedido cancelado',
    _ => 'Procesando...',
  };

  @override
  Widget build(BuildContext context) {
    if (_stream == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton()),
        body: Center(child: Text('Pedido no encontrado')),
      );
    }

    return StreamBuilder<OrderModel?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: const AppStateView(
              icon: Icons.cloud_off_rounded,
              title: 'No pudimos actualizar el pedido',
              message:
                  'Revisa tu conexión. El seguimiento se reanudará automáticamente.',
            ),
          );
        }
        final order = snap.data;
        final status = order?.status ?? 'confirmed';
        final active = _activeStep(status);
        final isDelivered = status == 'entregado';
        final isCancelled = status == 'cancelado';
        final shortId = (_orderId ?? '').length > 6
            ? _orderId!.substring(_orderId!.length - 6).toUpperCase()
            : (_orderId ?? '------').toUpperCase();

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              // ── Mapa real ──────────────────────────────────────
              SizedBox(
                height: 340,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: order == null
                          ? Container(
                              color: Theme.of(context).scaffoldBackgroundColor,
                            )
                          : _LiveTrackingMap(
                              order: order,
                              // Subscribe to the courier's live position ONLY
                              // while the order is active — cancelled the instant
                              // it is delivered/cancelled (StreamBuilder is not
                              // built then) and on dispose.
                              trackCourier: !isDelivered && !isCancelled,
                            ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 20,
                      child: _CircleBtn(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.chevron_left, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Panel inferior ─────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      20 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        // ETA + #pedido
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child:
                                  snap.connectionState ==
                                      ConnectionState.waiting
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _etaLabel(status),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '#RN-$shortId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (order != null) ...[
                          SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              order.storeName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Barra de progreso
                        Row(
                          children: List.generate(
                            _steps.length,
                            (i) => Expanded(
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: i < _steps.length - 1 ? 6 : 0,
                                ),
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: i <= active
                                      ? AppColors.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _steps.asMap().entries.map((e) {
                            final isActive = e.key == active;
                            final isLast = e.key == _steps.length - 1;
                            return Expanded(
                              child: Text(
                                e.value,
                                textAlign: e.key == 0
                                    ? TextAlign.left
                                    : isLast
                                    ? TextAlign.right
                                    : TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isActive
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: e.key <= active
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Banner de estado: cancelado / entregado / activo.
                        // Para 'cancelado' NO se muestra la simulación animada.
                        if (isCancelled)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Este pedido fue cancelado',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isDelivered)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '¡Tu pedido fue entregado!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Actualizando el estado de tu pedido...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Una vez el pedido termina (entregado o cancelado) no
                        // hay nada más que seguir: ofrecer volver al menú,
                        // limpiando todo el stack de navegación.
                        if (isDelivered || isCancelled) ...[
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Volver al inicio',
                            leading: Icon(
                              Icons.home_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            onTap: () =>
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/home',
                                  (route) => false,
                                ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Repartidor card. Shows the driver as soon as the order
                        // carries any courier reference: courierName (written on
                        // accept), a courierId/assignedCourierId, or a status
                        // past acceptance. The name comes from courierName when
                        // present; otherwise we stream couriers/{id} for the full
                        // details (vehicle, rating). Placeholder ("Buscando
                        // repartidor") only while no courier is known yet.
                        Builder(
                          builder: (context) {
                            final o = order;
                            if (o == null) {
                              return const _CourierCard(
                                courier: null,
                                assigned: false,
                              );
                            }
                            final name = o.courierName;
                            final hasName = name != null && name.isNotEmpty;
                            final courierId =
                                o.courierId ?? o.assignedCourierId;
                            final hasCourier =
                                hasName ||
                                courierId != null ||
                                const [
                                  'accepted',
                                  'picked_up',
                                  'en_camino',
                                  'entregado',
                                ].contains(o.status);
                            if (!hasCourier) {
                              return const _CourierCard(
                                courier: null,
                                assigned: false,
                              );
                            }
                            // No id to look up richer details: show the name alone.
                            if (courierId == null) {
                              return _CourierCard(
                                courier: null,
                                assigned: true,
                                fallbackName: hasName ? name : 'Repartidor',
                                orderId: o.id,
                              );
                            }
                            return StreamBuilder<CourierInfo?>(
                              stream: DbService.streamCourier(courierId),
                              builder: (context, cs) => _CourierCard(
                                courier: cs.data,
                                assigned: true,
                                fallbackName: hasName ? name : null,
                                orderId: o.id,
                              ),
                            );
                          },
                        ),

                        // Resumen del pedido
                        if (order != null) ...[
                          SizedBox(height: 14),
                          Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Resumen del pedido',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                          status,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        order.statusLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                ...order.items.map(
                                  (item) => Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${item.qty}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        Text(
                                          'S/ ${item.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                  height: 18,
                                ),
                                _SummaryRow(
                                  'Subtotal',
                                  'S/ ${order.subtotal.toStringAsFixed(2)}',
                                ),
                                const SizedBox(height: 4),
                                _SummaryRow(
                                  'Envío',
                                  'S/ ${order.deliveryFee.toStringAsFixed(2)}',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'S/ ${order.total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.observation != null) ...[
                                  Divider(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                    height: 18,
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.comment_outlined,
                                        size: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          order.observation!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
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

  Color _statusColor(String status) => switch (status) {
    'entregado' => AppColors.secondary,
    'cancelado' => AppColors.danger,
    _ => AppColors.primary,
  };
}

/// Real Google Map for order tracking. Shows the store and delivery markers
/// (when the order carries coordinates) plus the courier's live marker, streamed
/// from `courierLocations/{courierId}`.
///
/// Lifecycle discipline (critical for read costs): the courier stream is only
/// subscribed while [trackCourier] is true (i.e. the order is active). When the
/// order becomes delivered/cancelled the parent rebuilds with trackCourier=false
/// so the inner StreamBuilder is not built — its listener is torn down at once —
/// and it is likewise disposed when the tracking screen is popped.
class _LiveTrackingMap extends StatefulWidget {
  final OrderModel order;
  final bool trackCourier;
  const _LiveTrackingMap({required this.order, required this.trackCourier});

  @override
  State<_LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<_LiveTrackingMap> {
  GoogleMapController? _controller;
  // Signature of the marker set the camera was last framed to, so we only refit
  // when the composition changes (e.g. the courier marker first appears) rather
  // than on every position update.
  String _fitSignature = '';

  static const _puno = LatLng(-15.8402, -70.0219);

  LatLng? get _store =>
      (widget.order.storeLat != null && widget.order.storeLng != null)
      ? LatLng(widget.order.storeLat!, widget.order.storeLng!)
      : null;

  LatLng? get _delivery =>
      (widget.order.deliveryLat != null && widget.order.deliveryLng != null)
      ? LatLng(widget.order.deliveryLat!, widget.order.deliveryLng!)
      : null;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courierId = widget.order.courierId ?? widget.order.assignedCourierId;
    if (widget.trackCourier && courierId != null) {
      return StreamBuilder<CourierLocation?>(
        stream: DbService.streamCourierLocation(courierId),
        builder: (context, snap) => _buildMap(snap.data),
      );
    }
    return _buildMap(null);
  }

  Widget _buildMap(CourierLocation? courierLoc) {
    final store = _store;
    final delivery = _delivery;
    final courier = courierLoc != null
        ? LatLng(courierLoc.lat, courierLoc.lng)
        : null;

    final markers = <Marker>{
      if (store != null)
        Marker(
          markerId: const MarkerId('store'),
          position: store,
          infoWindow: InfoWindow(title: widget.order.storeName),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      if (delivery != null)
        Marker(
          markerId: const MarkerId('delivery'),
          position: delivery,
          infoWindow: const InfoWindow(title: 'Tu entrega'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      if (courier != null)
        Marker(
          markerId: const MarkerId('courier'),
          position: courier,
          infoWindow: const InfoWindow(title: 'Tu repartidor'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
    };

    // Frame the camera when the set of present markers changes.
    final points = <LatLng>[?store, ?delivery, ?courier];
    final signature = [
      if (store != null) 's',
      if (delivery != null) 'd',
      if (courier != null) 'c',
    ].join();
    if (signature != _fitSignature && points.isNotEmpty) {
      _fitSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit(points));
    }

    // Tell the customer the courier isn't sharing yet — whether none is
    // assigned or one is assigned but hasn't published a position. Only while
    // the order is active (trackCourier) and no real courier marker exists. We
    // never invent a fake marker.
    final awaitingCourier = widget.trackCourier && courier == null;

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: courier ?? delivery ?? store ?? _puno,
              zoom: 14,
            ),
            markers: markers,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            onMapCreated: (c) {
              _controller = c;
              if (points.isNotEmpty) {
                _fitSignature = signature;
                _fit(points);
              }
            },
          ),
        ),
        // Honest empty state: no marker is invented for the courier — we say so.
        if (awaitingCourier)
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El repartidor aún no comparte su ubicación.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _fit(List<LatLng> points) async {
    final controller = _controller;
    if (controller == null || points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CircleBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    ),
  );
}

/// Initials for an avatar from a free-form display name (e.g. "Juan Pérez" →
/// "JP"). Falls back to "R" (repartidor) when the name is empty.
String _initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'R';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

class _CourierCard extends StatelessWidget {
  final CourierInfo? courier;
  final bool assigned; // the order already has a courier
  final String? fallbackName; // order.courierName, shown until/unless the
  // couriers/{id} doc loads (or when there is no id to look up at all)
  final String? orderId;
  const _CourierCard({
    required this.courier,
    required this.assigned,
    this.fallbackName,
    this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final c = courier;
    final displayName = c?.name.isNotEmpty == true
        ? c!.name
        : (fallbackName != null && fallbackName!.isNotEmpty
              ? fallbackName!
              : 'Repartidor');
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD0B0),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: !assigned
                  ? Icon(
                      Icons.person_search,
                      size: 22,
                      color: AppColors.primary,
                    )
                  : Text(
                      c?.initials ?? _initialsOf(displayName),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !assigned ? 'Buscando repartidor...' : displayName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                if (assigned && c != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.motorcycle, size: 13),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          c.vehicleModel.isEmpty ? 'Vehículo' : c.vehicleModel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (c.vehiclePlate.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.vehiclePlate,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '★ ${c.rating.toStringAsFixed(1)} · ${c.totalDeliveries} entregas',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ] else if (!assigned) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Te asignaremos uno en breve',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    'Repartidor asignado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (assigned && c != null)
            Row(
              children: [
                GestureDetector(
                  onTap: orderId == null
                      ? null
                      : () => Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: orderId,
                        ),
                  child: _ActionBtn(
                    color: Theme.of(context).colorScheme.surface,
                    borderColor: Theme.of(context).colorScheme.outlineVariant,
                    child: Icon(Icons.chat_bubble_outline, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  color: AppColors.secondary,
                  child: Icon(Icons.phone, size: 20, color: Colors.white),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final Widget child;
  const _ActionBtn({
    required this.color,
    this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: borderColor != null
          ? Border.all(color: borderColor!, width: 1.5)
          : null,
    ),
    child: child,
  );
}
