import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../theme.dart';

/// A real Google Map showing the courier's live position and, when available,
/// a destination marker.
///
/// IMPORTANT: `OrderModel` currently carries NO destination coordinates, so
/// [destination] is null in every call today. The parameter exists so that,
/// once the customer app starts propagating lat/lng, the marker appears with
/// zero further changes here. While it is null the map shows only the courier
/// and the parent screen surfaces the "missing destination" notice.
///
/// Every location/permission failure is handled: the map falls back to Puno,
/// Perú and shows a clear, retryable message. It never crashes.
class CourierMap extends StatefulWidget {
  final LatLng? destination;
  final String destinationLabel;
  // Text shown in the centered loading card while the courier position is
  // being resolved (e.g. 'Buscando ruta al comercio').
  final String loadingLabel;

  const CourierMap({
    super.key,
    this.destination,
    this.destinationLabel = 'Destino',
    this.loadingLabel = 'Buscando ruta...',
  });

  @override
  State<CourierMap> createState() => _CourierMapState();
}

class _CourierMapState extends State<CourierMap> {
  static const _puno = LatLng(LocationService.punoLat, LocationService.punoLng);

  GoogleMapController? _controller;
  StreamSubscription<Position>? _sub;
  LatLng? _me;
  String? _error;
  bool _hasPermission = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await LocationService.current();
    if (!mounted) return;
    if (res.ok) {
      _hasPermission = true;
      final pos = res.position!;
      setState(() {
        _me = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
      _moveCamera(_me!);
      _listen();
    } else {
      setState(() {
        _error = res.error;
        _loading = false;
      });
    }
  }

  void _listen() {
    _sub?.cancel();
    _sub = LocationService.stream().listen((pos) {
      if (!mounted) return;
      setState(() => _me = LatLng(pos.latitude, pos.longitude));
    }, onError: (_) {});
  }

  Future<void> _moveCamera(LatLng target) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(target, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    if (widget.destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination!,
        infoWindow: InfoWindow(title: widget.destinationLabel),
      ));
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _me ?? widget.destination ?? _puno,
              zoom: 15,
            ),
            myLocationEnabled: _hasPermission,
            myLocationButtonEnabled: _hasPermission,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: markers,
            onMapCreated: (c) {
              _controller = c;
              final focus = _me ?? widget.destination;
              if (focus != null) _moveCamera(focus);
            },
          ),
        ),
        // Loading + error overlays live INSIDE the map layer (this Positioned.
        // fill is the bottom child of the route screen's Stack), so they always
        // render below the top destination card and the bottom action panel.
        // Both are centered on the map, horizontally and vertically.
        if (_loading)
          Positioned.fill(
            child: Center(child: _MapLoadingCard(text: widget.loadingLabel)),
          ),
        // On failure the spinner is replaced by a clear, retryable message —
        // the overlay never spins forever and the screen stays usable.
        if (_error != null)
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _MapNotice(message: _error!, onRetry: _init),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapLoadingCard extends StatelessWidget {
  final String text;
  const _MapLoadingCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: CourierColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CourierColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: CourierColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: CourierColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _MapNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: CourierColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourierColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded,
              size: 20, color: CourierColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: CourierColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Reintentar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: CourierColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
