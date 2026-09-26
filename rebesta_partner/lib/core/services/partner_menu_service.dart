import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'partner_auth_service.dart';
import '../constants/api_constants.dart';

// ============================================================
// PARTNER MENU SERVICE
// ============================================================
//
// Full menu CRUD against the backend:
// - GET    /menu/partner        list own dishes
// - POST   /menu                create (multipart, image optional)
// - PATCH  /menu/:id            update (multipart, image optional)
// - PATCH  /menu/:id/status     toggle availability
// - DELETE /menu/:id            delete
// ============================================================

class PartnerMenuService {
  static const String baseUrl = ApiConstants.baseUrl;

  // ============================================================
  // GET PARTNER MENU
  // ============================================================

  static Future<List<Map<String, dynamic>>> getPartnerMenu() async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    debugPrint('================================');
    debugPrint('🍽️ GET PARTNER MENU');
    debugPrint('================================');

    final response = await http.get(
      Uri.parse('$baseUrl/menu/partner'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('================================');

    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load menu',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid menu response');
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Failed to load menu',
      );
    }

    final menu = decoded['menu'];

    if (menu is! List) {
      return [];
    }

    return menu
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  // ============================================================
  // CREATE DISH
  // ============================================================

  static Future<Map<String, dynamic>> createDish({
    required String name,
    required double price,
    required String category,
    required String description,
    required bool isVeg,
    required bool isAvailable,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageMimeType,
  }) {
    return _saveDish(
      method: 'POST',
      url: '$baseUrl/menu',
      name: name,
      price: price,
      category: category,
      description: description,
      isVeg: isVeg,
      isAvailable: isAvailable,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
      imageMimeType: imageMimeType,
    );
  }

  // ============================================================
  // UPDATE DISH
  // ============================================================

  static Future<Map<String, dynamic>> updateDish(
    String id, {
    required String name,
    required double price,
    required String category,
    required String description,
    required bool isVeg,
    required bool isAvailable,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageMimeType,
  }) {
    return _saveDish(
      method: 'PATCH',
      url: '$baseUrl/menu/$id',
      name: name,
      price: price,
      category: category,
      description: description,
      isVeg: isVeg,
      isAvailable: isAvailable,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
      imageMimeType: imageMimeType,
    );
  }

  // ============================================================
  // SAVE (shared by create + update)
  //
  // Sends multipart/form-data so the dish photo travels with
  // the same request - no separate upload round-trip.
  // ============================================================

  static Future<Map<String, dynamic>> _saveDish({
    required String method,
    required String url,
    required String name,
    required double price,
    required String category,
    required String description,
    required bool isVeg,
    required bool isAvailable,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageMimeType,
  }) async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final request = http.MultipartRequest(
      method,
      Uri.parse(url),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    request.fields['category'] = category;
    request.fields['description'] = description;
    request.fields['isVeg'] = isVeg ? 'true' : 'false';

    request.fields['isAvailable'] =
        isAvailable ? 'true' : 'false';

    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFileName ?? 'dish.jpg',
          contentType: MediaType.parse(
            imageMimeType ?? 'image/jpeg',
          ),
        ),
      );
    }

    final streamed = await request.send();

    final response =
        await http.Response.fromStream(streamed);

    debugPrint('================================');
    debugPrint('🍽️ SAVE DISH [$method $url]');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('================================');

    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Failed to save dish',
      );
    }

    if (decoded is! Map) {
      throw Exception('Invalid save response');
    }

    return Map<String, dynamic>.from(decoded);
  }

  // ============================================================
  // TOGGLE AVAILABILITY
  // ============================================================

  static Future<void> toggleAvailability(
    String id,
    bool isAvailable,
  ) async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/menu/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'isAvailable': isAvailable,
      }),
    );

    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body);

      throw Exception(
        decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Failed to update availability',
      );
    }
  }

  // ============================================================
  // DELETE DISH
  // ============================================================

  static Future<void> deleteDish(String id) async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/menu/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to delete dish');
    }
  }
}
