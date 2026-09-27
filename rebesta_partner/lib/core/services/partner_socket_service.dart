import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'partner_auth_service.dart';

// ============================================================
// PARTNER SOCKET (singleton)
// ============================================================
//
// Connected ONCE for the whole session (from the dashboard
// shell) so the restaurant hears 'new-order' and
// 'order-status' on EVERY tab - not just while the Orders tab
// happens to be open. Screens register listeners; the socket
// outlives page navigation.
// ============================================================

class PartnerSocketService {
  PartnerSocketService._();

  static final PartnerSocketService instance =
      PartnerSocketService._();

  IO.Socket? _socket;

  // ============================================================
  // LISTENERS (any screen that cares about order events)
  // ============================================================

  final List<void Function()> _newOrderListeners = [];

  void addOnNewOrderListener(
    void Function() listener,
  ) {
    _newOrderListeners.add(listener);
  }

  void removeOnNewOrderListener(
    void Function() listener,
  ) {
    _newOrderListeners.remove(listener);
  }

  // ============================================================
  // CONNECT (idempotent - safe to call from anywhere)
  // ============================================================

  Future<void> connect({
    required String restaurantPartnerId,
  }) async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      debugPrint('❌ PARTNER SOCKET: no auth token - not connecting');
      return;
    }

    debugPrint('================================');
    debugPrint('📡 PARTNER SOCKET CONNECT');
    debugPrint(
      'Restaurant Partner ID: $restaurantPartnerId',
    );
    debugPrint('================================');

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

    _socket!.onConnect((_) {
      debugPrint('✅ PARTNER SOCKET CONNECTED');

      _socket!.emit(
        'join_partner',
        restaurantPartnerId,
      );
    });

    _socket!.on('new-order', (data) {
      debugPrint('================================');
      debugPrint('🔔 NEW ORDER RECEIVED');
      debugPrint('Data: $data');
      debugPrint('================================');

      for (final listener in List.of(_newOrderListeners)) {
        listener();
      }
    });

    _socket!.on('order-status', (data) {
      debugPrint('================================');
      debugPrint('📦 ORDER STATUS UPDATE');
      debugPrint('Data: $data');
      debugPrint('================================');

      for (final listener in List.of(_newOrderListeners)) {
        listener();
      }
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

  // ============================================================
  // DISCONNECT (logout only - NOT on page navigation)
  // ============================================================

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
