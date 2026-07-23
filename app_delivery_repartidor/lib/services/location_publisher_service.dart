import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Outcome of attempting to start publishing the courier's position.
enum PublishStartResult { ok, serviceDisabled, denied, deniedForever, error }

extension PublishStartResultMessage on PublishStartResult {
  /// User-facing Spanish message to warn the courier that the customer won't be
  /// able to see them, or null when publishing started fine.
  String? get warning => switch (this) {
        PublishStartResult.ok => null,
        PublishStartResult.serviceDisabled =>
          'El GPS está apagado: el cliente no podrá ver tu ubicación en el mapa.',
        PublishStartResult.denied =>
          'Permiso de ubicación denegado: el cliente no podrá verte en el mapa.',
        PublishStartResult.deniedForever =>
          'Permiso de ubicación bloqueado. Habilítalo en Ajustes para que el '
              'cliente pueda verte.',
        PublishStartResult.error =>
          'No se pudo compartir tu ubicación: el cliente no podrá verte.',
      };
}

/// Publishes the courier's live position to `courierLocations/{uid}` — a
/// document SEPARATE from `couriers/{uid}` and `orders/{id}`, so these
/// high-frequency writes never bloat documents that are read across the apps.
///
/// STRICT COST DISCIPLINE (every rule enforced here):
///  - Runs ONLY while the courier is online AND has an active order. The single
///    orchestrator (MainShell) guarantees that precondition; this service is
///    never started from anywhere else.
///  - Distance-based stream (geolocator `distanceFilter: 30`) — it publishes
///    after the courier moves ≥ 30 m, NOT on a timer.
///  - Plus a hard 10 s floor between writes even when moving fast.
///  - [stop] ends the GPS stream and clears `activeOrderId`. Idempotent.
///  - Every permission/service failure is handled — it never throws.
///
/// Singleton: exactly one instance owns the logic, so it is never duplicated
/// across screens.
class LocationPublisherService {
  LocationPublisherService._();
  static final LocationPublisherService instance =
      LocationPublisherService._();

  static final _db = FirebaseFirestore.instance;

  /// Minimum metres moved before a new write (also geolocator's distanceFilter;
  /// re-checked here defensively).
  static const double _minMeters = 30;

  /// Minimum time between writes, regardless of distance moved.
  static const Duration _minInterval = Duration(seconds: 10);

  StreamSubscription<Position>? _sub;
  String? _uid;
  String? _orderId;
  DateTime? _lastWriteAt;
  double? _lastLat;
  double? _lastLng;
  bool _starting = false;

  bool get isPublishing => _sub != null;

  /// Start (or retarget) publishing for [uid] on [orderId]. Safe to call
  /// repeatedly: it is a no-op once already running for that order, and just
  /// retargets `activeOrderId` (without restarting GPS) when the active order
  /// changes for the same courier.
  Future<PublishStartResult> start({
    required String uid,
    required String orderId,
  }) async {
    // Already publishing for this exact order → nothing to do.
    if (_sub != null && _uid == uid && _orderId == orderId) {
      return PublishStartResult.ok;
    }
    // Same courier, different active order → retarget the same running stream.
    if (_sub != null && _uid == uid) {
      _orderId = orderId;
      _lastWriteAt = null;
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        await _write(p);
      } catch (_) {}
      return PublishStartResult.ok;
    }
    if (_starting) return PublishStartResult.ok;
    _starting = true;
    try {
      final permission = await _ensurePermission();
      if (permission != PublishStartResult.ok) return permission;

      _uid = uid;
      _orderId = orderId;
      _lastWriteAt = null;
      _lastLat = null;
      _lastLng = null;
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 30,
        ),
      ).listen(_onPosition, onError: (_) {});

      // Write one immediate fix so the customer sees the courier right away —
      // the distance-filtered stream may not emit until the device moves.
      try {
        final first = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        await _write(first);
      } catch (_) {}
      return PublishStartResult.ok;
    } catch (_) {
      await stop();
      return PublishStartResult.error;
    } finally {
      _starting = false;
    }
  }

  Future<PublishStartResult> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return PublishStartResult.serviceDisabled;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return PublishStartResult.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return PublishStartResult.deniedForever;
    }
    return PublishStartResult.ok;
  }

  void _onPosition(Position pos) {
    final now = DateTime.now();
    // 10 s floor between writes.
    if (_lastWriteAt != null && now.difference(_lastWriteAt!) < _minInterval) {
      return;
    }
    // 30 m floor (defensive; distanceFilter already enforces it).
    if (_lastLat != null && _lastLng != null) {
      final moved = Geolocator.distanceBetween(
          _lastLat!, _lastLng!, pos.latitude, pos.longitude);
      if (moved < _minMeters) return;
    }
    _write(pos);
  }

  Future<void> _write(Position pos) async {
    final uid = _uid;
    if (uid == null) return;
    _lastWriteAt = DateTime.now();
    _lastLat = pos.latitude;
    _lastLng = pos.longitude;
    try {
      await _db.collection('courierLocations').doc(uid).set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'heading': pos.heading,
        'updatedAt': FieldValue.serverTimestamp(),
        'activeOrderId': _orderId,
      });
    } catch (_) {
      // Best-effort: a failed location write must never disrupt the delivery.
    }
  }

  /// Stop publishing and clear `activeOrderId` on the document (best-effort).
  /// Idempotent — safe to call when not publishing.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    final uid = _uid;
    _uid = null;
    _orderId = null;
    _lastWriteAt = null;
    _lastLat = null;
    _lastLng = null;
    if (uid != null) {
      try {
        await _db.collection('courierLocations').doc(uid).set({
          'activeOrderId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }
}
