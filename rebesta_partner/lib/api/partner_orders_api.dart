import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/services/partner_auth_service.dart';

class PartnerOrdersApi {
  // ============================================================
  // AUTH HEADERS
  // ============================================================

  Future<Map<String, String>> _headers() async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Partner session expired');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET ORDERS
  // ============================================================

  Future<List<Map<String, dynamic>>> getOrders() async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/partner-orders',
      ),
      headers: headers,
    );

    print('========================================');
print('PARTNER ORDERS API');
print('URL: ${ApiConstants.baseUrl}/partner-orders');
print('STATUS: ${response.statusCode}');
print('BODY: ${response.body}');
print('========================================');

    if (response.statusCode == 401) {
      throw Exception('Partner session expired');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to load orders (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid orders response');
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Failed to load orders',
      );
    }

    final orders = decoded['orders'];

    if (orders is! List) {
      throw Exception(
        'Invalid orders data returned by server',
      );
    }

    return orders
        .whereType<Map>()
        .map(
          (order) => Map<String, dynamic>.from(order),
        )
        .toList();
  }

  // ============================================================
  // GET SINGLE ORDER
  // ============================================================

  Future<Map<String, dynamic>> getOrder(
    String orderId,
  ) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/partner-orders/$orderId',
      ),
      headers: headers,
    );

    if (response.statusCode == 401) {
      throw Exception('Partner session expired');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to load order (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid order response');
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Failed to load order',
      );
    }

    if (decoded['order'] is! Map) {
      throw Exception('Order data not found');
    }

    return Map<String, dynamic>.from(
      decoded['order'],
    );
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

 // ============================================================
// UPDATE ORDER STATUS
// ============================================================

Future<Map<String, dynamic>> updateStatus({
  required String orderId,
  required String status,
}) async {
  final headers = await _headers();

  final url =
      '${ApiConstants.baseUrl}/partner-orders/$orderId/status';

  final requestBody = {
    'status': status,
  };

  print('========================================');
  print('PARTNER UPDATE STATUS API');
  print('METHOD: PATCH');
  print('URL: $url');
  print('BODY: ${jsonEncode(requestBody)}');
  print('========================================');

  final response = await http.patch(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(requestBody),
  );

  print('========================================');
  print('PARTNER UPDATE STATUS RESPONSE');
  print('STATUS: ${response.statusCode}');
  print('BODY: ${response.body}');
  print('========================================');

  if (response.statusCode == 401) {
    throw Exception('Partner session expired');
  }

  if (response.statusCode < 200 ||
      response.statusCode >= 300) {
    String message =
        'Failed to update order (${response.statusCode})';

    try {
      final errorBody = jsonDecode(response.body);

      if (errorBody is Map) {
        message =
            errorBody['message']?.toString() ??
            errorBody['error']?.toString() ??
            message;
      }
    } catch (_) {
      // Response wasn't JSON.
    }

    throw Exception(message);
  }

  final decoded = jsonDecode(response.body);

  if (decoded is! Map) {
    throw Exception(
      'Invalid status update response',
    );
  }

  if (decoded['success'] != true) {
    throw Exception(
      decoded['message']?.toString() ??
          'Failed to update order',
    );
  }

  if (decoded['order'] is! Map) {
    throw Exception(
      'Updated order not returned',
    );
  }

  return Map<String, dynamic>.from(
    decoded['order'],
  );
}
}