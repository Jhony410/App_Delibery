import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme.dart';
import '../widgets.dart';

/// Resultado devuelto por [MapPickerScreen] al confirmar: coordenadas elegidas
/// y el texto de calle detectado (reverse geocoding, o un genérico si falló).
class PickedLocation {
  final double latitude;
  final double longitude;
  final String street;
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.street,
  });
}

/// Mapa a pantalla completa, estilo pin-drop: el usuario mueve el mapa bajo un
/// pin fijo en el centro. Al detenerse el mapa se hace reverse geocoding (con
/// salvaguardas de costo) para sugerir la calle. Confirmar devuelve una
/// [PickedLocation]; el botón atrás cancela sin devolver nada.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _punoCenter = LatLng(-15.8402, -70.0219);
  static const double _defaultZoom = 16;

  // Caché en memoria de la sesión: coordenada redondeada -> texto de calle.
  // static para sobrevivir entre aperturas del selector en la misma sesión.
  static final Map<String, String> _sessionCache = {};

  GoogleMapController? _mapController;
  LatLng _cameraTarget = _punoCenter;
  double? _lat;
  double? _lng;
  String _street = 'Ubicación seleccionada';
  bool _geocoding = false;
  bool _argsResolved = false;

  final Geocoding _geocoder = Geocoding();
  Timer? _debounce;
  LatLng?
  _lastQueried; // último punto realmente consultado (para el filtro 25 m)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsResolved) return;
    _argsResolved = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is LatLng) {
      _cameraTarget = arg;
      _lat = arg.latitude;
      _lng = arg.longitude;
      // Geocodifica el punto inicial una vez.
      _scheduleGeocode(immediate: true);
    } else {
      // Sin punto inicial: centra en la ubicación actual.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _goToCurrentLocation(),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _cameraTarget = target;
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, _defaultZoom),
      );
      // El onCameraIdle posterior al animate disparará el geocoding.
    } catch (_) {
      // Silencioso: el usuario puede mover el mapa manualmente.
    }
  }

  // ── Reverse geocoding con salvaguardas de costo ────────────
  void _onCameraIdle() {
    // SOLO al detenerse el mapa (nunca en onCameraMove), y con debounce.
    _scheduleGeocode();
  }

  void _scheduleGeocode({bool immediate = false}) {
    _debounce?.cancel();
    _debounce = Timer(
      Duration(milliseconds: immediate ? 0 : 800),
      () => _reverseGeocode(_cameraTarget),
    );
  }

  Future<void> _reverseGeocode(LatLng target) async {
    setState(() {
      _lat = target.latitude;
      _lng = target.longitude;
    });

    // Filtro de distancia: no consultar si el punto está a < 25 m del último.
    final last = _lastQueried;
    if (last != null) {
      final meters = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        target.latitude,
        target.longitude,
      );
      if (meters < 25) return;
    }

    // Caché de sesión (clave redondeada a ~11 m).
    final key =
        '${target.latitude.toStringAsFixed(4)},${target.longitude.toStringAsFixed(4)}';
    if (_sessionCache.containsKey(key)) {
      setState(() {
        _street = _sessionCache[key]!;
        _lastQueried = target;
      });
      return;
    }

    setState(() => _geocoding = true);
    try {
      final placemarks = await _geocoder.placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      final text = placemarks.isEmpty
          ? 'Ubicación seleccionada'
          : _formatPlacemark(placemarks.first);
      _sessionCache[key] = text;
      if (mounted) {
        setState(() {
          _street = text;
          _lastQueried = target;
        });
      }
    } catch (_) {
      // Sin red o error del servicio: genérico y edición manual en Pantalla B.
      if (mounted) {
        setState(() {
          _street = 'Ubicación seleccionada';
          _lastQueried = target;
        });
      }
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  String _formatPlacemark(Placemark p) {
    final parts = <String>[];
    final street = (p.street ?? '').trim();
    final thoroughfare = (p.thoroughfare ?? '').trim();
    final subLocality = (p.subLocality ?? '').trim();
    final locality = (p.locality ?? '').trim();

    if (street.isNotEmpty && street != (p.name ?? '').trim()) {
      parts.add(street);
    } else if (thoroughfare.isNotEmpty) {
      parts.add(thoroughfare);
    } else if ((p.name ?? '').trim().isNotEmpty) {
      parts.add(p.name!.trim());
    }
    if (subLocality.isNotEmpty) {
      parts.add(subLocality);
    } else if (locality.isNotEmpty) {
      parts.add(locality);
    }
    final result = parts.toSet().where((e) => e.isNotEmpty).join(', ');
    return result.isEmpty ? 'Ubicación seleccionada' : result;
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedLocation(
        latitude: _lat ?? _cameraTarget.latitude,
        longitude: _lng ?? _cameraTarget.longitude,
        street: _street,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _cameraTarget,
              zoom: _defaultZoom,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
            onCameraMove: (pos) => _cameraTarget = pos.target,
            onCameraIdle: _onCameraIdle,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
          // Pin fijo en el centro (el vértice inferior apunta al centro exacto).
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(
                  Icons.location_on,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          // Botón atrás (cancela sin guardar).
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: _CircleBtn(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.chevron_left, size: 22),
            ),
          ),
          // Botón "mi ubicación".
          Positioned(
            right: 16,
            bottom: 200,
            child: _CircleBtn(
              onTap: _goToCurrentLocation,
              child: Icon(
                Icons.my_location,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          18 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mueve el mapa para que el pin quede justo en tu puerta',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.place, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: _geocoding
                      ? Row(
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
                              'Buscando dirección…',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _street,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(label: 'Confirmar ubicación', onTap: _confirm),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _CircleBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    ),
  );
}
