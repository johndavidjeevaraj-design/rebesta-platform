import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint(
        '📍 LOCATION TRACKING ALREADY RUNNING',
      );
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
        debugPrint(
          '📍 GPS POSITION: '
          '${position.latitude}, ${position.longitude}',
        );

        _sendLocation(
          position.latitude,
          position.longitude,
        );
      },
      onError: (error) {
        debugPrint(
          '❌ LOCATION STREAM ERROR: $error',
        );
      },
    );

    _isTracking = true;

    debugPrint(
      '🚴 DELIVERY LOCATION TRACKING STARTED',
    );
  }

  // ============================================================
  // STOP LOCATION TRACKING
  // ============================================================

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();

    _positionSubscription = null;

    _isTracking = false;

    debugPrint(
      '🛑 DELIVERY LOCATION TRACKING STOPPED',
    );
  }

  // ============================================================
  // SEND LOCATION TO BACKEND
  // ============================================================

  Future<void> _sendLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('=================================');
      debugPrint('📍 SENDING DELIVERY LOCATION');
      debugPrint('LATITUDE: $latitude');
      debugPrint('LONGITUDE: $longitude');
      debugPrint(
        'POST: ${ApiConstants.updateLocation}',
      );
      debugPrint('=================================');

      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.post(
        ApiConstants.updateLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
        options: options,
      );

      debugPrint(
        '✅ LOCATION UPDATE SUCCESS: '
        '${response.statusCode}',
      );

      debugPrint(
        'LOCATION RESPONSE: '
        '${response.data}',
      );
    } on DioException catch (e) {
      debugPrint(
        '❌ LOCATION UPDATE FAILED: '
        '${e.response?.statusCode}',
      );

      debugPrint(
        'LOCATION RESPONSE: '
        '${e.response?.data}',
      );
    } catch (e) {
      debugPrint(
        '❌ LOCATION ERROR: $e',
      );
    }
  }
}