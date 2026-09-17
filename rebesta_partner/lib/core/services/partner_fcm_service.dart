import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

import 'partner_auth_service.dart';

class PartnerFcmService {
  // ============================================================
  // CONFIG
  // ============================================================

  //static const String baseUrl = 'http://10.0.2.2:3000';
  static const String baseUrl = 'http://172.16.255.167:3000';

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // NEW ORDER CALLBACK
  // ============================================================

  static Future<void> Function(
    Map<String, dynamic> data,
  )? onNewOrder;

  // ============================================================
  // CURRENT ORDER
  // ============================================================

  static String? _activeOrderId;

  static Timer? _ringTimer;

  static bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize({
    Future<void> Function(
      Map<String, dynamic> data,
    )? onOrder,
  }) async {
    if (_initialized) {
      onNewOrder = onOrder;
      return;
    }

    try {
      debugPrint('================================');
      debugPrint('🔔 INITIALIZING PARTNER FCM');
      debugPrint('================================');

      onNewOrder = onOrder;

      // ========================================================
      // FCM PERMISSION
      // ========================================================

      final settings =
          await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
      );

      debugPrint(
        '🔔 Notification permission: '
        '${settings.authorizationStatus}',
      );

      // ========================================================
      // LOCAL NOTIFICATIONS INITIALIZATION
      // ========================================================

      const androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initializationSettings =
          InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse:
            _onNotificationResponse,
      );

      // ========================================================
      // ANDROID NOTIFICATION PERMISSION
      // ========================================================

      final androidImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation
          ?.requestNotificationsPermission();

      // ========================================================
      // CREATE HIGH PRIORITY ORDER CHANNEL
      // ========================================================

      const channel = AndroidNotificationChannel(
        'partner_new_orders',
        'New Orders',
        description:
            'Incoming restaurant orders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation
          ?.createNotificationChannel(channel);

      // ========================================================
      // FCM TOKEN
      // ========================================================

      final token =
          await _messaging.getToken();

      debugPrint('================================');
      debugPrint('🔥 PARTNER FCM TOKEN');
      debugPrint(
        'Token exists: ${token != null}',
      );
      debugPrint(
        'Token: ${token ?? 'NULL'}',
      );
      debugPrint('================================');

      if (token != null &&
          token.isNotEmpty) {
        await registerToken(token);
      }

      // ========================================================
      // TOKEN REFRESH
      // ========================================================

      _messaging.onTokenRefresh.listen(
        (newToken) async {
          debugPrint(
            '🔄 PARTNER FCM TOKEN REFRESHED',
          );

          await registerToken(newToken);
        },
      );

      // ========================================================
      // FOREGROUND FCM
      // ========================================================

      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) async {
          debugPrint('================================');
          debugPrint('🔔 PARTNER NEW ORDER FCM');
          debugPrint(
            'Title: ${message.notification?.title}',
          );
          debugPrint(
            'Body: ${message.notification?.body}',
          );
          debugPrint(
            'Data: ${message.data}',
          );
          debugPrint('================================');

          final data =
              Map<String, dynamic>.from(
            message.data,
          );

          final orderId =
              data['orderId'] ??
                  data['order_id'];

          if (orderId == null) {
            debugPrint(
              '⚠️ FCM has no orderId',
            );
            return;
          }

          data['orderId'] =
              orderId.toString();

          // ====================================================
          // LOCAL NOTIFICATION
          // ====================================================

          await _showNewOrderNotification(
            data,
          );

          // ====================================================
          // START RING + VIBRATION
          // ====================================================

          _startOrderAlert(
            orderId.toString(),
          );

          // ====================================================
          // TELL DASHBOARD
          // ====================================================

          if (onNewOrder != null) {
            await onNewOrder!(data);
          }
        },
      );

      _initialized = true;

      debugPrint(
        '✅ PARTNER FCM INITIALIZED',
      );
    } catch (e, stack) {
      debugPrint(
        '❌ PARTNER FCM INITIALIZATION ERROR: $e',
      );

      debugPrint(
        stack.toString(),
      );
    }
  }

  // ============================================================
  // LOCAL NOTIFICATION
  // ============================================================

  static Future<void>
      _showNewOrderNotification(
    Map<String, dynamic> data,
  ) async {
    final orderId =
        data['orderId']?.toString() ??
            'NEW';

    final amount =
        data['amount']?.toString() ??
            data['totalAmount']?.toString() ??
            '';

    final title =
        '🔔 New Order';

    final body = amount.isNotEmpty
        ? 'Order #${_shortOrderId(orderId)} • ₹$amount'
        : 'You have received a new order.';

    const androidDetails =
        AndroidNotificationDetails(
      'partner_new_orders',
      'New Orders',
      channelDescription:
          'Incoming restaurant orders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      category:
          AndroidNotificationCategory.call,
    );

    const details =
        NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: 9999,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(data),
    );
  }

  // ============================================================
  // RING + VIBRATION
  // ============================================================

  static void _startOrderAlert(
    String orderId,
  ) {
    _activeOrderId = orderId;

    _ringTimer?.cancel();

    // Immediate vibration.
    _vibrate();

    // Repeat vibration every 2 seconds.
    _ringTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async {
        if (_activeOrderId == orderId) {
          await _vibrate();
        }
      },
    );
  }

  // ============================================================
  // VIBRATION
  // ============================================================

  static Future<void> _vibrate() async {
    try {
      final hasVibrator =
          await Vibration.hasVibrator();

      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: [
            0,
            700,
            300,
            700,
            300,
          ],
          intensities: [
            0,
            255,
            0,
            255,
            0,
          ],
        );
      }
    } catch (e) {
      debugPrint(
        '⚠️ Vibration error: $e',
      );
    }
  }

  // ============================================================
  // STOP ORDER ALERT
  // ============================================================

  static Future<void> stopOrderAlert(
    String orderId,
  ) async {
    if (_activeOrderId != orderId) {
      return;
    }

    debugPrint(
      '🔕 STOPPING ORDER ALERT: $orderId',
    );

    _activeOrderId = null;

    _ringTimer?.cancel();
    _ringTimer = null;

    try {
      await Vibration.cancel();
    } catch (_) {}

    await _localNotifications.cancel(
      id: 9999,
    );
  }

  // ============================================================
  // NOTIFICATION TAP
  // ============================================================

  static void _onNotificationResponse(
    NotificationResponse response,
  ) {
    debugPrint(
      '🔔 PARTNER NOTIFICATION TAPPED',
    );

    debugPrint(
      'Payload: ${response.payload}',
    );
  }

  // ============================================================
  // REGISTER TOKEN
  // ============================================================

  static Future<void> registerToken(
    String token,
  ) async {
    try {
      final jwt =
          await PartnerAuthService.getToken();

      if (jwt == null ||
          jwt.isEmpty) {
        debugPrint(
          '⚠️ Partner JWT missing',
        );
        return;
      }

      final response =
          await http.post(
        Uri.parse(
          '$baseUrl/fcm/partner',
        ),
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $jwt',
        },
        body: jsonEncode({
          'token': token,
          'platform': 'android',
        }),
      );

      debugPrint(
        'FCM registration status: '
        '${response.statusCode}',
      );

      debugPrint(
        'FCM registration body: '
        '${response.body}',
      );
    } catch (e) {
      debugPrint(
        '❌ REGISTER PARTNER FCM ERROR: $e',
      );
    }
  }

  // ============================================================
  // SHORT ORDER ID
  // ============================================================

  static String _shortOrderId(
    String id,
  ) {
    if (id.length <= 8) {
      return id.toUpperCase();
    }

    return id
        .substring(0, 8)
        .toUpperCase();
  }
}