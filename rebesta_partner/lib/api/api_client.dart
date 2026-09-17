import 'package:http/http.dart' as http;

import '../core/services/partner_auth_service.dart';

class ApiClient {
  static const String baseUrl =
      'http://172.16.255.167:3000';

  static Future<Map<String, String>> headers() async {
    final token =
        await PartnerAuthService.getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(
    String endpoint,
  ) async {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await headers(),
    );
  }

  static Future<http.Response> post(
    String endpoint, {
    required String body,
  }) async {
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await headers(),
      body: body,
    );
  }

  static Future<http.Response> patch(
    String endpoint, {
    required String body,
  }) async {
    return http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await headers(),
      body: body,
    );
  }

  static Future<http.Response> delete(
    String endpoint,
  ) async {
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await headers(),
    );
  }
}