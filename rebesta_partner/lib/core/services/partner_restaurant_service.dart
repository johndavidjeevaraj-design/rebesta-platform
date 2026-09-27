import 'dart:convert';

import 'package:http/http.dart' as http;

import 'partner_auth_service.dart';
import '../constants/api_constants.dart';

// ============================================================
// PARTNER RESTAURANT SERVICE
// ============================================================
//
// Own-restaurant operations:
// - GET   /restaurants/me     profile + open/closed status
// - PATCH /restaurants/me     open / close the store
// ============================================================

class PartnerRestaurantService {
  static const String baseUrl = ApiConstants.baseUrl;

  // ============================================================
  // MY RESTAURANT
  // ============================================================

  static Future<Map<String, dynamic>> getMyRestaurant() async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final response = await http.get(
      Uri.parse('$baseUrl/restaurants/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final decoded = await _handle(response);

    final restaurant = decoded['restaurant'];

    if (restaurant is! Map) {
      throw Exception(
        'No restaurant found for this account',
      );
    }

    return Map<String, dynamic>.from(restaurant);
  }

  // ============================================================
  // OPEN / CLOSE THE STORE
  // ============================================================

  static Future<void> updateStoreStatus(bool isOpen) async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/restaurants/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'isOpen': isOpen,
      }),
    );

    await _handle(response);
  }

  // ============================================================
  // STORE HOURS
  // (null times clear the schedule)
  // ============================================================

  static Future<void> updateStoreHours({
    String? openingTime,
    String? closingTime,
    required List<int> closedDays,
  }) async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/restaurants/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'openingTime': openingTime,
        'closingTime': closingTime,
        'closedDays': closedDays,
      }),
    );

    await _handle(response);
  }

  // ============================================================
  // SHARED RESPONSE HANDLING
  // ============================================================

  static Future<Map<String, dynamic>> _handle(
    http.Response response,
  ) async {
    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Request failed',
      );
    }

    if (decoded is! Map) {
      throw Exception('Invalid response');
    }

    return Map<String, dynamic>.from(decoded);
  }
}
