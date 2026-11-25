import 'dart:async';
import 'package:geolocator/geolocator.dart';

import '../core/constants/api_constants.dart';
import '../core/network/delivery_api_client.dart';

class DeliveryLocationService {
  DeliveryLocationService._();

  static final DeliveryLocationService instance =
      DeliveryLocationService._();

  StreamSubscription<Position>? _positionSubscription;

  bool _isTracking = false;

  bool get isTracking => _isTracking;

  // ============================================================
  // START LOCATION TRACKING
  // ============================================================

  Future<void> startTracking() async {
    if (_isTracking) {
      return;
    }

    // ----------------------------------------------------------
    // Check GPS service
    // ----------------------------------------------------------

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS.',
      );
    }

    // ----------------------------------------------------------
    // Check permission
    // ----------------------------------------------------------

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. '
        'Please enable it from Settings.',
      );
    }

    // ----------------------------------------------------------
    // Start GPS stream
    // ----------------------------------------------------------

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _sendLocation(
          position.latitude,
          position.longitude,
        );
      },
      onError: (error) {

      },
    );

    _isTracking = true;

  }

  // ============================================================
  // STOP LOCATION TRACKING
  // ============================================================

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();

    _positionSubscription = null;

    _isTracking = false;

  }

  // ============================================================
  // SEND LOCATION TO BACKEND
  // ============================================================

  Future<void> _sendLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final options =
          await DeliveryApiClient.authOptions();

      await DeliveryApiClient.dio.post(
        ApiConstants.updateLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
        options: options,
      );


    } on DioException {
      // Location updates are best-effort; avoid logging response bodies.
    } catch (_) {
      // Avoid logging sensitive location or exception payloads.
    }
  }
}