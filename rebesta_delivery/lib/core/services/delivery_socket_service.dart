import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../constants/api_constants.dart';
import '../storage/delivery_auth_storage.dart';

// ============================================================
// DELIVERY SOCKET SERVICE
// ============================================================
//
// Realtime connection for the rider app.
//
// 1. Joins the rider's personal room (delivery_<id>)
//    -> targeted updates (order assignment, etc.)
//
// 2. Joins the shared delivery feed room
//    -> "new-order"  : fired the moment a restaurant marks
//       an order ready (or a rider cancels and the order
//       returns to the pool)
//    -> "order-taken": fired when another rider accepts an
//       order, so it can be removed from the local list
//
// ============================================================

class DeliverySocketService {
  DeliverySocketService._();

  static final DeliverySocketService instance =
      DeliverySocketService._();

  socket_io.Socket? _socket;

  bool get isConnected =>
      _socket?.connected ?? false;

  // ============================================================
  // LISTENERS
  //
  // Several screens can listen at the same time
  // (dashboard + available orders), so we keep lists.
  // ============================================================

  final List<void Function(Map<String, dynamic> order)>
      _newOrderListeners = [];

  final List<void Function(String orderId)>
      _orderTakenListeners = [];

  void addOnNewOrderListener(
    void Function(Map<String, dynamic> order) listener,
  ) {
    _newOrderListeners.add(listener);
  }

  void removeOnNewOrderListener(
    void Function(Map<String, dynamic> order) listener,
  ) {
    _newOrderListeners.remove(listener);
  }

  void addOnOrderTakenListener(
    void Function(String orderId) listener,
  ) {
    _orderTakenListeners.add(listener);
  }

  void removeOnOrderTakenListener(
    void Function(String orderId) listener,
  ) {
    _orderTakenListeners.remove(listener);
  }

  // ============================================================
  // ORDER OFFER (personal - Swiggy-style assignment)
  // ============================================================

  final List<void Function(Map<String, dynamic> offer)>
      _orderOfferListeners = [];

  void addOnOrderOfferListener(
    void Function(Map<String, dynamic> offer) listener,
  ) {
    _orderOfferListeners.add(listener);
  }

  void removeOnOrderOfferListener(
    void Function(Map<String, dynamic> offer) listener,
  ) {
    _orderOfferListeners.remove(listener);
  }

  // ============================================================
  // OFFER EXPIRED / TAKEN (closes the offer dialog)
  // ============================================================

  final List<void Function(Map<String, dynamic> data)>
      _offerExpiredListeners = [];

  void addOnOfferExpiredListener(
    void Function(Map<String, dynamic> data) listener,
  ) {
    _offerExpiredListeners.add(listener);
  }

  void removeOnOfferExpiredListener(
    void Function(Map<String, dynamic> data) listener,
  ) {
    _offerExpiredListeners.remove(listener);
  }

  // ============================================================
  // CONNECT
  // ============================================================

  Future<void> connect() async {
    final token = await DeliveryAuthStorage.getToken();

    if (token == null || token.isEmpty) {
      debugPrint('❌ DELIVERY SOCKET: no auth token - not connecting');
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint(
        '🚴 DELIVERY SOCKET ALREADY CONNECTED',
      );

      return;
    }

    debugPrint('=================================');
    debugPrint('🚴 DELIVERY SOCKET CONNECTING');
    debugPrint(
      'URL: ${ApiConstants.baseUrl}',
    );
    debugPrint('=================================');

    // JWT travels in the handshake - the gateway rejects
    // unauthenticated connections.
    _socket = socket_io.io(
      ApiConstants.baseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) async {
      debugPrint('=================================');
      debugPrint('✅ DELIVERY SOCKET CONNECTED');
      debugPrint(
        'Socket ID: ${_socket!.id}',
      );
      debugPrint('=================================');

      await _joinRooms();
    });

    _socket!.onDisconnect((reason) {
      debugPrint(
        '🚴 DELIVERY SOCKET DISCONNECTED: $reason',
      );
    });

    _socket!.onConnectError((error) {
      debugPrint(
        '❌ DELIVERY SOCKET CONNECT ERROR: $error',
      );
    });

    _socket!.onError((error) {
      debugPrint(
        '❌ DELIVERY SOCKET ERROR: $error',
      );
    });

    // ============================================================
    // NEW ORDER (broadcast to all online riders)
    // ============================================================

    _socket!.on('new-order', (data) {
      debugPrint('=================================');
      debugPrint('🔔 NEW ORDER AVAILABLE');
      debugPrint('ORDER: $data');
      debugPrint('=================================');

      final order = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};

      // Copy the list so a listener can safely
      // add / remove listeners while we iterate.

      for (final listener in List.of(_newOrderListeners)) {
        listener(order);
      }
    });

    // ============================================================
    // ORDER TAKEN (another rider accepted the order)
    // ============================================================

    _socket!.on('order-taken', (data) {
      debugPrint(
        '🚫 ORDER TAKEN BY ANOTHER RIDER: $data',
      );

      final orderId = data is Map
          ? data['orderId']?.toString() ?? ''
          : '';

      if (orderId.isEmpty) return;

      for (final listener in List.of(_orderTakenListeners)) {
        listener(orderId);
      }
    });

    // ============================================================
    // ORDER OFFER (personal - Swiggy-style assignment)
    // ============================================================

    _socket!.on('order-offer', (data) {
      debugPrint('=================================');
      debugPrint('🔔🔔 ORDER OFFER JUST FOR YOU');
      debugPrint('OFFER: $data');
      debugPrint('=================================');

      final offer = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};

      for (final listener in List.of(_orderOfferListeners)) {
        listener(offer);
      }
    });

    // ============================================================
    // OFFER EXPIRED / TAKEN (close the offer dialog)
    // ============================================================

    _socket!.on('offer-expired', (data) {
      debugPrint(
        '⌛ ORDER OFFER CLOSED: $data',
      );

      final payload = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};

      for (final listener in List.of(_offerExpiredListeners)) {
        listener(payload);
      }
    });

    _socket!.connect();
  }

  // ============================================================
  // JOIN ROOMS
  // ============================================================

  Future<void> _joinRooms() async {
    final partnerId =
        await DeliveryAuthStorage.getDeliveryPartnerId();

    if (partnerId == null || partnerId.isEmpty) {
      debugPrint(
        '⚠️ NO DELIVERY PARTNER ID - SKIPPING ROOM JOIN',
      );

      return;
    }

    // The backend joins BOTH rooms for us:
    // - delivery_<partnerId> (personal)
    // - delivery_feed        (new order broadcast)

    _socket?.emit(
      'join_delivery',
      partnerId,
    );

    debugPrint(
      '🚴 JOINED: delivery_$partnerId + delivery_feed',
    );
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  void disconnect() {
    _socket?.dispose();

    _socket = null;

    debugPrint(
      '🚴 DELIVERY SOCKET DISCONNECTED (manual)',
    );
  }
}
