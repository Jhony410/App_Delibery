import 'package:url_launcher/url_launcher.dart';

/// Opens the phone's Google Maps (or default maps app) for real turn-by-turn
/// navigation — we intentionally do NOT compute routes in-app (no Directions
/// API). Prefers coordinates when available; otherwise falls back to a text
/// query (an address). Returns false if nothing could be launched.
class ExternalMaps {
  static Future<bool> open({double? lat, double? lng, String? query}) async {
    final Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else if (query != null && query.trim().isNotEmpty) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query.trim())}');
    } else {
      return false;
    }
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
