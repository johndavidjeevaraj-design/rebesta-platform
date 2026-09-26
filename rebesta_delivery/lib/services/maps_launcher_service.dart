import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// MAPS LAUNCHER
// ============================================================
//
// Deep-links into Google Maps turn-by-turn navigation and the
// phone dialer - the two things a rider needs mid-trip without
// losing the app's delivery status flow.
//
// Navigation strategy (Swiggy-style):
//   1. google.navigation: URI -> opens the Google Maps app
//      straight into navigation mode (best).
//   2. https://www.google.com/maps/dir/ universal link ->
//      works even without the app installed (browser).
//
// Destination can be coordinates (customer drop-off) or an
// address query (restaurants have no coordinates stored).
// ============================================================

class MapsLauncher {
  // ============================================================
  // OPEN TURN-BY-TURN NAVIGATION
  // ============================================================

  static Future<void> launchNavigation({
    double? latitude,
    double? longitude,
    String? query,
  }) async {
    String? destination;

    if (latitude != null && longitude != null) {
      destination = '$latitude,$longitude';
    } else if (query != null && query.isNotEmpty) {
      destination = Uri.encodeComponent(query);
    }

    if (destination == null) {
      debugPrint('MAPS LAUNCHER: no destination to navigate to');

      return;
    }

    // ------------------------------------------------------------
    // 1. Google Maps app -> straight into navigation mode
    // ------------------------------------------------------------

    final appUri = Uri.parse(
      'google.navigation:q=$destination&mode=d',
    );

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(
          appUri,
          mode: LaunchMode.externalApplication,
        );

        return;
      }
    } catch (e) {
      debugPrint('MAPS LAUNCHER: app uri failed: $e');
    }

    // ------------------------------------------------------------
    // 2. Universal link fallback (browser / other maps apps)
    // ------------------------------------------------------------

    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/'
      '?api=1&destination=$destination&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );

        return;
      }
    } catch (e) {
      debugPrint('MAPS LAUNCHER: web uri failed: $e');
    }

    debugPrint(
      'MAPS LAUNCHER: no maps app or browser available',
    );
  }

  // ============================================================
  // CALL A PHONE NUMBER (opens the dialer)
  // ============================================================

  static Future<void> launchCall(
    String? phone,
  ) async {
    if (phone == null || phone.isEmpty) {
      debugPrint('MAPS LAUNCHER: no phone number to call');

      return;
    }

    final uri = Uri.parse('tel:$phone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('MAPS LAUNCHER: call failed: $e');
    }
  }
}
