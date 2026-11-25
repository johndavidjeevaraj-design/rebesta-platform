import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

class DeliverySocketService {
  IO.Socket? _socket;

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

    disconnect();

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

    socket.onConnect((_) {
      // Rejoin after every reconnect. The server must validate
      // the authenticated identity against this room request.
      socket.emit('join_customer', customerId);
    });

    socket.on('delivery_location', (data) {
      if (data is! Map) return;
      final location = Map<String, dynamic>.from(data);
      if (location['orderId']?.toString() != orderId) return;
      onLocationUpdate(location);
    });

    socket.on('order_status', (data) {
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);
      if (payload['orderId']?.toString() != orderId) return;
      onStatusUpdate?.call(payload);
    });

    socket.on('delivery_assigned', (data) {
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);
      if (payload['orderId']?.toString() != orderId) return;
      onStatusUpdate?.call(payload);
    });

    socket.connect();
  }

  void disconnect() {
    final socket = _socket;
    if (socket == null) return;
    socket.disconnect();
    socket.dispose();
    _socket = null;
  }
}
