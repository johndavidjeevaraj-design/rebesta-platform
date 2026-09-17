import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PartnerAuthService {
 //tatic const String baseUrl = 'http://10.0.2.2:3000';

  static const String baseUrl = 'http://172.16.255.167:3000';

  // ============================================================
  // SEND OTP
  // ============================================================

  // ============================================================
// SEND OTP
// ============================================================

// ============================================================
// SEND OTP
// ============================================================

static Future<String> sendOtp({
  required String mobile,
}) async {
  final phone = mobile.replaceAll(
    RegExp(r'\D'),
    '',
  );

  if (phone.length != 10) {
    throw Exception(
      'Enter a valid 10 digit mobile number',
    );
  }

  debugPrint('================================');
  debugPrint('📱 SENDING PARTNER OTP');
  debugPrint('Mobile: $phone');
  debugPrint('================================');

  final response = await http.post(
    Uri.parse(
      '$baseUrl/partner-auth/send-otp',
    ),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'mobile': phone,
    }),
  );

  debugPrint('================================');
  debugPrint('📡 OTP RESPONSE');
  debugPrint('Status Code: ${response.statusCode}');
  debugPrint('Body: ${response.body}');
  debugPrint('================================');

  final data = jsonDecode(response.body);

  if (data is! Map) {
    throw Exception(
      'Invalid OTP response',
    );
  }

  // ==========================================================
  // ACCEPT SUCCESS RESPONSE
  // ==========================================================

  final message =
      data['message']?.toString() ?? '';

  final status =
      data['Status']?.toString() ?? '';

  final details =
      data['Details']?.toString() ?? '';

  // Backend may return success in different formats.
  final isSuccess =
      response.statusCode >= 200 &&
      response.statusCode < 300 &&
      (
        status.toLowerCase() == 'success' ||
        message.toLowerCase().contains('otp sent') ||
        message.toLowerCase().contains('success')
      );

  if (!isSuccess) {
    throw Exception(
      message.isNotEmpty
          ? message
          : details.isNotEmpty
              ? details
              : 'Failed to send OTP',
    );
  }

  // ==========================================================
  // SESSION ID
  // ==========================================================

  final sessionId =
      data['Details']?.toString() ??
      data['sessionId']?.toString() ??
      data['session_id']?.toString();

  if (sessionId == null ||
      sessionId.isEmpty ||
      sessionId == 'null') {
    debugPrint(
      '⚠️ OTP sent but no sessionId returned.',
    );

    throw Exception(
      'OTP sent successfully, but OTP session ID was not returned.',
    );
  }

  debugPrint('================================');
  debugPrint('✅ PARTNER OTP SENT');
  debugPrint('Session ID: $sessionId');
  debugPrint('================================');

  return sessionId;
}

  // ============================================================
  // VERIFY OTP
  // ============================================================

  static Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
    required String sessionId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/partner-auth/verify-otp',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mobile': mobile,
        'otp': otp,
        'sessionId': sessionId,
      }),
    );

    final data = jsonDecode(response.body);

    if (data is! Map) {
      throw Exception(
        'Invalid OTP verification response',
      );
    }

    if (data['registered'] != true) {
      throw Exception(
        data['message']?.toString() ??
            'Partner account not found',
      );
    }

    final token =
        data['access_token']?.toString();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Partner token was not returned',
      );
    }

    final partner =
        data['partner'] is Map
            ? Map<String, dynamic>.from(
                data['partner'],
              )
            : <String, dynamic>{};

    await _saveSession(
      token,
      partner,
    );

    return Map<String, dynamic>.from(
      data,
    );
  }

  // ============================================================
  // SAVE SESSION
  // ============================================================

 static Future<void> _saveSession(
  String token,
  Map<String, dynamic> partner,
) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'partner_token',
    token,
  );

  final partnerId =
      partner['id']?.toString();

  final restaurantPartnerId =
      partner['restaurantPartnerId']?.toString();

  final partnerName =
      partner['name']?.toString();

  final partnerEmail =
      partner['email']?.toString();

  final partnerMobile =
      partner['mobile']?.toString();

  final restaurantName =
      partner['restaurantName']?.toString();

  if (partnerId != null &&
      partnerId.isNotEmpty) {
    await prefs.setString(
      'partner_user_id',
      partnerId,
    );
  }

  if (restaurantPartnerId != null &&
      restaurantPartnerId.isNotEmpty) {
    await prefs.setString(
      'restaurant_partner_id',
      restaurantPartnerId,
    );
  }

  await prefs.setString(
    'partner_name',
    partnerName ?? '',
  );

  await prefs.setString(
    'partner_email',
    partnerEmail ?? '',
  );

  await prefs.setString(
    'partner_mobile',
    partnerMobile ?? '',
  );

  await prefs.setString(
    'restaurant_name',
    restaurantName ?? '',
  );
}

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  static Future<bool> isLoggedIn() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString(
      'partner_token',
    );

    return token != null &&
        token.isNotEmpty;
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'partner_token',
    );
  }

  static Future<Map<String, dynamic>?> getPartnerProfile() async {
  final token = await getToken();

  if (token == null || token.isEmpty) {
    return null;
  }

  try {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/partner-auth/me',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('================================');
    debugPrint('👤 PARTNER PROFILE');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('================================');

    if (response.statusCode == 401) {
      await logout();
      return null;
    }

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      return null;
    }

    if (decoded['success'] != true) {
      return null;
    }

    final partner = decoded['partner'];

    if (partner is! Map) {
      return null;
    }

    final profile =
        Map<String, dynamic>.from(partner);

    // Save restaurant information locally.
    final restaurantName =
        profile['restaurantName']?.toString();

    if (restaurantName != null &&
        restaurantName.isNotEmpty) {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'restaurant_name',
        restaurantName,
      );
    }

    return profile;
  } catch (e) {
    debugPrint(
      '❌ GET PARTNER PROFILE ERROR: $e',
    );

    return null;
  }
}

  // ============================================================
  // GET PARTNER USER ID
  // ============================================================

  static Future<String?> getPartnerUserId() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'partner_user_id',
    );
  }

  // ============================================================
  // GET PARTNER NAME
  // ============================================================

  static Future<String?> getPartnerName() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'partner_name',
    );
  }

  // ============================================================
  // GET RESTAURANT PARTNER ID
  // ============================================================

  static Future<String?>
      getRestaurantPartnerId() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'restaurant_partner_id',
    );
  }

  static Future<String?> getRestaurantName() async {
  final prefs =
      await SharedPreferences.getInstance();

  return prefs.getString(
    'restaurant_name',
  );
}

  // ============================================================
  // GET PARTNER MOBILE
  // ============================================================

  static Future<String?> getPartnerMobile() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'partner_mobile',
    );
  }

  // ============================================================
  // GET PARTNER EMAIL
  // ============================================================

  static Future<String?> getPartnerEmail() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'partner_email',
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      'partner_token',
    );

    await prefs.remove(
      'partner_user_id',
    );

    await prefs.remove(
      'restaurant_partner_id',
    );

    await prefs.remove(
      'partner_name',
    );

    await prefs.remove(
      'partner_email',
    );

    await prefs.remove(
      'partner_mobile',
    );

    await prefs.remove(
      'restaurant_name'
    );
  }
}