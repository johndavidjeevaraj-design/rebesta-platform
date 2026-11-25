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
            return;
    }

                
    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
                            });

    _socket!.onDisconnect((reason) {
          });

    _socket!.onConnectError((error) {
          });

    _socket!.onError((error) {
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

      }

  // ============================================================
  // REMOVE LOCATION LISTENER
  // ============================================================

  void offDeliveryLocation() {
    _socket?.off(
      'delivery_location',
    );

      }

  // ============================================================
  // DISCONNECT
  // ============================================================

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

      }
}