import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PartnerSocketService {
  IO.Socket? _socket;

  String? _restaurantPartnerId;

  void connect({
    required String restaurantPartnerId,
    required VoidCallback onNewOrder,
  }) {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _restaurantPartnerId = restaurantPartnerId;

    debugPrint('================================');
    debugPrint('📡 PARTNER SOCKET CONNECT');
    debugPrint('Restaurant Partner ID: $restaurantPartnerId');
    debugPrint('================================');

    _socket = IO.io(
      //ttp://10.0.2.2:3000',
      'http://172.16.255.167:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('✅ PARTNER SOCKET CONNECTED');

      _socket!.emit(
        'join_partner',
        restaurantPartnerId,
      );

      debugPrint(
        '📡 Joined partner_$restaurantPartnerId',
      );
    });

    _socket!.on('new-order', (data) {
      debugPrint('================================');
      debugPrint('🔔 NEW ORDER RECEIVED');
      debugPrint('Data: $data');
      debugPrint('================================');

      onNewOrder();
    });

    _socket!.on('order-status', (data) {
      debugPrint('================================');
      debugPrint('📦 ORDER STATUS UPDATE');
      debugPrint('Data: $data');
      debugPrint('================================');

      onNewOrder();
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ PARTNER SOCKET DISCONNECTED');
    });

    _socket!.onConnectError((error) {
      debugPrint(
        '❌ PARTNER SOCKET ERROR: $error',
      );
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}