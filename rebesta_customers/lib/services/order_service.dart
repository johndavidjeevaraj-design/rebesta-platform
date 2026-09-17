import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';

class OrderService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // ============================================================
  // TOKEN
  // ============================================================

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString('token');

  debugPrint('================================');
  debugPrint('🔐 ORDER AUTH TOKEN');
  debugPrint('Token exists: ${token != null && token.isNotEmpty}');
  debugPrint(
    'Token preview: ${token == null ? 'NULL' : '${token.substring(0, token.length > 20 ? 20 : token.length)}...'}',
  );
  debugPrint('================================');

  return token;
}
  // ============================================================
  // AUTH HEADERS
  // ============================================================

  Future<Options> _authOptions() async {
    final token = await _getToken();

    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );
  }

  // ============================================================
  // CREATE ORDER
  // ============================================================
Future<Map<String, dynamic>> checkout({
  String? addressId,
  required String restaurantPartnerId,
  String? couponCode,
  bool wallet = false,
}) async {
  final data = {
    'restaurantPartnerId': restaurantPartnerId,
    if (addressId != null && addressId.isNotEmpty)
      'addressId': addressId,   // only include when delivery address exists
    if (couponCode != null && couponCode.isNotEmpty)
      'couponCode': couponCode,
    'wallet': wallet,
  };

  debugPrint('================================');
  debugPrint('📦 POST /orders/checkout');
  debugPrint('addressId: $addressId');
  debugPrint(
    'restaurantPartnerId: $restaurantPartnerId',
  );
  debugPrint('couponCode: $couponCode');
  debugPrint('wallet: $wallet');
  debugPrint('DATA: $data');
  debugPrint('================================');

  final response = await _dio.post(
    '/orders/checkout',
    data: data,
    options: await _authOptions(),
  );

  debugPrint('================================');
  debugPrint('📦 CHECKOUT RESPONSE');
  debugPrint('STATUS: ${response.statusCode}');
  debugPrint('DATA: ${response.data}');
  debugPrint('================================');

  return Map<String, dynamic>.from(
    response.data,
  );
}
  // ============================================================
  // GET MY ORDERS
  // ============================================================

  Future<Map<String, dynamic>> getMyOrders() async {
    final response = await _dio.get(
      '/orders/my',
      options: await _authOptions(),
    );

    debugPrint('================================');
  debugPrint('📦 GET MY ORDERS RESPONSE');
  debugPrint('STATUS: ${response.statusCode}');
  debugPrint('DATA: ${response.data}');
  debugPrint('================================');

    return Map<String, dynamic>.from(
      response.data,
    );
  }

  // ============================================================
  // GET ORDER
  // ============================================================

  Future<Map<String, dynamic>> getOrder(
    String orderId,
  ) async {
    final response = await _dio.get(
      '/orders/$orderId',
      options: await _authOptions(),
    );

    return Map<String, dynamic>.from(
      response.data,
    );
  }

  // ============================================================
  // TRACK ORDER
  // ============================================================

  Future<Map<String, dynamic>> trackOrder(
    String orderId,
  ) async {
    final response = await _dio.get(
      '/orders/$orderId/tracking',
      options: await _authOptions(),
    );

    return Map<String, dynamic>.from(
      response.data,
    );
  }
}