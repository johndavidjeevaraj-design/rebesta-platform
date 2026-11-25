import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../core/constants/api_constants.dart';

class SocketService {
  SocketService._();

  static final SocketService instance = SocketService._();
  IO.Socket? _socket;
  String? _customerId;

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final customerId = prefs.getString('customerId');
    if (token == null || token.isEmpty || customerId == null || customerId.isEmpty) {
      disconnect();
      return;
    }
    if (_socket != null && _socket!.connected && _customerId == customerId) return;
    disconnect();
    _customerId = customerId;
    final socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );
    _socket = socket;
    socket.onConnect((_) => socket.emit('join_customer', customerId));
    socket.connect();
  }

  Future<void> joinCustomer(String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString('customerId');
    if (storedId == null || storedId.isEmpty || storedId != customerId) return;
    await connect();
    if (_socket?.connected == true) _socket!.emit('join_customer', storedId);
  }

  void onDeliveryLocation(void Function(dynamic data) callback) {
    _socket?.off('delivery_location');
    _socket?.on('delivery_location', callback);
  }

  void offDeliveryLocation() => _socket?.off('delivery_location');

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _customerId = null;
  }
}
