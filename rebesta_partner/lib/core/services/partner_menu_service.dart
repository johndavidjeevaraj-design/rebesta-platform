import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'partner_auth_service.dart';
import '../constants/api_constants.dart';

class PartnerMenuService {

 //atic const String baseUrl = 'http://10.0.2.2:3000';
  static const String baseUrl = ApiConstants.baseUrl;

  // ============================================================
  // GET PARTNER MENU
  // ============================================================

  static Future<List<Map<String, dynamic>>> getPartnerMenu() async {
    final token =
        await PartnerAuthService.getToken();

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

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid menu response',
      );
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
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }
}