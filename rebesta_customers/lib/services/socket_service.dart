import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../core/constants/api_constants.dart';

class SocketService {
  SocketService._();

  static final SocketService instance =
      SocketService._();

  IO.Socket? _socket;

  // ============================================================
  // CONNECT
  // ============================================================

  void connect() {
    if (_socket != null && _socket!.connected) {
      debugPrint('🔌 CUSTOMER SOCKET ALREADY CONNECTED');
      return;
    }

    debugPrint('=================================');
    debugPrint('🔌 CUSTOMER SOCKET CONNECTING');
    debugPrint(
      'URL: ${ApiConstants.baseUrl}',
    );
    debugPrint('=================================');

    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('=================================');
      debugPrint('✅ CUSTOMER SOCKET CONNECTED');
      debugPrint(
        'Socket ID: ${_socket!.id}',
      );
      debugPrint('=================================');
    });

    _socket!.onDisconnect((reason) {
      debugPrint(
        '🔌 CUSTOMER SOCKET DISCONNECTED: $reason',
      );
    });

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

    _socket!.connect();
  }

  // ============================================================
  // JOIN CUSTOMER ROOM
  // ============================================================

  void joinCustomer(String customerId) {
    if (_socket == null) {
      connect();
    }

    debugPrint(
      '👤 CUSTOMER JOIN ROOM: customer_$customerId',
    );

    _socket!.emit(
      'join_customer',
      customerId,
    );
  }

  // ============================================================
  // LISTEN TO DELIVERY LOCATION
  // ============================================================

  void onDeliveryLocation(
    void Function(dynamic data) callback,
  ) {
    _socket?.off('delivery_location');

    _socket?.on(
      'delivery_location',
      callback,
    );

    debugPrint(
      '📡 CUSTOMER LISTENING: delivery_location',
    );
  }

  // ============================================================
  // REMOVE LOCATION LISTENER
  // ============================================================

  void offDeliveryLocation() {
    _socket?.off(
      'delivery_location',
    );

    debugPrint(
      '📡 CUSTOMER STOPPED: delivery_location',
    );
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    debugPrint(
      '🔌 CUSTOMER SOCKET DISPOSED',
    );
  }
}