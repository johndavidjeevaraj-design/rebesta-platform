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
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final customerId = prefs.getString('customerId');

    if (customerId == null || customerId.isEmpty) {
      throw Exception('Customer ID not found');
    }

    debugPrint('================================');
    debugPrint('📡 CUSTOMER LIVE SOCKET');
    debugPrint('Customer ID: $customerId');
    debugPrint('Order ID: $orderId');
    debugPrint('Socket URL: ${ApiConstants.baseUrl}');
    debugPrint('================================');

    // Prevent duplicate connections
    disconnect();

    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
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