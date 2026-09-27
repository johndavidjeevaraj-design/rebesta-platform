import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

class DeliverySocketService {
  IO.Socket? _socket;

  // ============================================================
  // CONNECT CUSTOMER
  // ============================================================

  Future<void> connect({
    required String orderId,
    required void Function(Map<String, dynamic>) onLocationUpdate,
    void Function(Map<String, dynamic>)? onStatusUpdate,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final customerId = prefs.getString('customerId');
    final token = prefs.getString('token');

    if (customerId == null || customerId.isEmpty) {
      throw Exception('Customer ID not found');
    }

    if (token == null || token.isEmpty) {
      throw Exception('Auth token not found');
    }

    debugPrint('================================');
    debugPrint('📡 CUSTOMER LIVE SOCKET');
    debugPrint('Customer ID: $customerId');
    debugPrint('Order ID: $orderId');
    debugPrint('Socket URL: ${ApiConstants.baseUrl}');
    debugPrint('================================');

    // Prevent duplicate connections
    disconnect();

    // JWT travels in the handshake - the gateway rejects
    // unauthenticated connections.
    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    // ==========================================================
    // CONNECT
    // ==========================================================

    _socket!.onConnect((_) {
      debugPrint('✅ CUSTOMER SOCKET CONNECTED');

      // Join customer room
      _socket!.emit(
        'join_customer',
        customerId,
      );

      debugPrint(
        '📡 Joined customer_$customerId',
      );
    });

    // ==========================================================
    // CONNECTION ERROR
    // ==========================================================

    _socket!.onConnectError((error) {
      debugPrint(
        '❌ CUSTOMER SOCKET CONNECT ERROR: $error',
      );
    });

    _socket!.onError((error) {
      debugPrint(
        '❌ CUSTOMER SOCKET ERROR: $error',
      );
    });

    // ==========================================================
    // DISCONNECT
    // ==========================================================

    _socket!.onDisconnect((reason) {
      debugPrint(
        '⚠️ CUSTOMER SOCKET DISCONNECTED: $reason',
      );
    });

    // ==========================================================
    // LIVE DELIVERY LOCATION
    // ==========================================================

    _socket!.on(
      'delivery_location',
      (data) {
        debugPrint('================================');
        debugPrint('📍 LIVE DELIVERY LOCATION');
        debugPrint('DATA: $data');
        debugPrint('================================');

        if (data is! Map) {
          return;
        }

        final location =
            Map<String, dynamic>.from(data);

        // Only accept location updates
        // for the order currently being tracked.
        if (location['orderId']?.toString() != orderId) {
          debugPrint(
            '⚠️ Ignoring location for another order',
          );
          return;
        }

        onLocationUpdate(location);
      },
    );

    // ==========================================================
    // ORDER STATUS (instant tracking refresh - no more waiting
    // for the polling timer)
    // ==========================================================

    _socket!.on(
      'order_status',
      (data) {
        debugPrint('📦 ORDER STATUS EVENT: $data');

        if (data is! Map) return;

        final payload = Map<String, dynamic>.from(data);

        if (payload['orderId']?.toString() != orderId) {
          return;
        }

        onStatusUpdate?.call(payload);
      },
    );

    // ==========================================================
    // DELIVERY ASSIGNED (a rider just took the order)
    // ==========================================================

    _socket!.on(
      'delivery_assigned',
      (data) {
        debugPrint('🚴 DELIVERY ASSIGNED EVENT: $data');

        if (data is! Map) return;

        final payload = Map<String, dynamic>.from(data);

        if (payload['orderId']?.toString() != orderId) {
          return;
        }

        onStatusUpdate?.call(payload);
      },
    );

    _socket!.connect();
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  void disconnect() {
    if (_socket == null) {
      return;
    }

    debugPrint(
      '🔌 Disconnecting customer socket',
    );

    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
  }
}