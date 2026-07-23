import 'package:geolocator/geolocator.dart';

/// Result of a location request. Exactly one of [position] / [error] is set.
/// [error] is a user-facing Spanish message ready to show in the UI.
class LocationResult {
  final Position? position;
  final String? error;
  const LocationResult({this.position, this.error});

  bool get ok => position != null;
}

/// Thin wrapper over `geolocator`. Handles every permission / service state
/// gracefully and never throws to the caller — the UI decides what to render
/// from [LocationResult.error].
class LocationService {
  /// Default fallback center when no location is available: Puno, Perú.
  static const double punoLat = -15.8402;
  static const double punoLng = -70.0219;

  /// Resolve the current position once, requesting permission if needed.
  static Future<LocationResult> current() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        error: 'El GPS está apagado. Actívalo para ver tu ubicación.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(
        error: 'Permiso de ubicación denegado.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        error: 'Permiso de ubicación bloqueado. Habilítalo desde Ajustes.',
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationResult(position: pos);
    } catch (_) {
      return const LocationResult(
        error: 'No se pudo obtener tu ubicación.',
      );
    }
  }

  /// Live stream of positions (used to keep the courier marker following the
  /// device). Emits only after permission has already been granted.
  static Stream<Position> stream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      );
}
