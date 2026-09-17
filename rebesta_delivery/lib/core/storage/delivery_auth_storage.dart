import 'package:shared_preferences/shared_preferences.dart';

class DeliveryAuthStorage {
  DeliveryAuthStorage._();

  static const String _tokenKey = 'delivery_auth_token';
  static const String _partnerIdKey = 'delivery_partner_id';

  static Future<void> saveSession({
    required String token,
    required String deliveryPartnerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(
      _partnerIdKey,
      deliveryPartnerId,
    );
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  static Future<String?> getDeliveryPartnerId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_partnerIdKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_partnerIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }
}