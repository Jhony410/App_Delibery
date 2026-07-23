import 'package:cloud_firestore/cloud_firestore.dart';

/// One courier's last published position, read from `courierLocations/{uid}`.
/// Written by the courier app while it has an active delivery.
class CourierLocationDoc {
  final String courierId;
  final double lat;
  final double lng;
  final double? heading;
  final DateTime? updatedAt;
  final String? activeOrderId;

  const CourierLocationDoc({
    required this.courierId,
    required this.lat,
    required this.lng,
    this.heading,
    this.updatedAt,
    this.activeOrderId,
  });

  factory CourierLocationDoc.fromMap(String id, Map<String, dynamic> m) =>
      CourierLocationDoc(
        courierId: id,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        heading: (m['heading'] as num?)?.toDouble(),
        updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
        activeOrderId: m['activeOrderId'] as String?,
      );

  /// True when the last update is recent enough to treat the courier as live.
  bool isFresh(DateTime now, {Duration maxAge = const Duration(minutes: 10)}) =>
      updatedAt != null && now.difference(updatedAt!) <= maxAge;
}

class CourierLocationService {
  static final _col =
      FirebaseFirestore.instance.collection('courierLocations');

  /// Real-time list of every courier position document. Docs without valid
  /// coordinates are skipped. Freshness/staleness is decided by the caller so
  /// the "disconnected" count can be shown honestly.
  static Stream<List<CourierLocationDoc>> streamAll() {
    return _col.snapshots().map((s) => s.docs
        .where((d) => d.data()['lat'] != null && d.data()['lng'] != null)
        .map((d) => CourierLocationDoc.fromMap(d.id, d.data()))
        .toList());
  }
}
