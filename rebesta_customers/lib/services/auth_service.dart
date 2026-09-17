import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../models/login_response.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  // ============================================================
  // EMAIL/PASSWORD LOGIN
  // ============================================================

  Future<LoginResponse> login({
    required String? email,
    required String password,
  }) async {
    final response = await _dio.post(
      "/customer-auth/login",
      data: {
        "email": email,
        "password": password,
      },
    );

    final login = LoginResponse.fromJson(response.data);

    await _saveLogin(login);

    return login;
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<String> sendOtp({
    required String phone,
  }) async {
    final response = await _dio.post(
      "/customer-auth/send-otp",
      data: {
        "mobile": phone,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception("Invalid OTP response");
    }

    if (data["Status"] != "Success") {
      throw Exception(
        data["Details"]?.toString() ?? "Failed to send OTP",
      );
    }

    final sessionId = data["Details"]?.toString();

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception("OTP session ID was not returned");
    }

    return sessionId;
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<LoginResponse?> verifyOtp({
    required String phone,
    required String otp,
    required String sessionId,
  }) async {
    final response = await _dio.post(
      "/customer-auth/verify-otp",
      data: {
        "mobile": phone,
        "otp": otp,
        "sessionId": sessionId,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception(
        "Invalid OTP verification response",
      );
    }

    // ==========================================================
    // EXISTING CUSTOMER
    // ==========================================================

    if (data["token"] != null) {
      final login = LoginResponse.fromJson(
        Map<String, dynamic>.from(data),
      );

      await _saveLogin(login);

      return login;
    }

    // ==========================================================
    // NEW CUSTOMER
    // ==========================================================

    // OTP verified successfully.
    // Backend says customer doesn't exist.
    //
    // We DON'T save login yet.
    // NameScreen will collect the name and then
    // completeProfile() will create the customer.

    return null;
  }

  // ============================================================
  // COMPLETE NEW CUSTOMER PROFILE
  // ============================================================

  Future<LoginResponse> completeProfile({
    required String mobile,
    required String name,
  }) async {
    final response = await _dio.post(
      "/customer-auth/complete-profile",
      data: {
        "mobile": mobile,
        "name": name,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception(
        "Invalid profile completion response",
      );
    }

    if (data["token"] == null) {
      throw Exception(
        data["message"]?.toString() ??
            "Failed to complete profile",
      );
    }

    final login = LoginResponse.fromJson(
      Map<String, dynamic>.from(data),
    );

    await _saveLogin(login);

    return login;
  }

  // ============================================================
  // SAVE LOGIN SESSION
  // ============================================================

  Future<void> _saveLogin(LoginResponse login) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      "token",
      login.token,
    );

    await prefs.setString(
      "customerId",
      login.customer.id,
    );

    await prefs.setString(
      "customerName",
      login.customer.name,
    );

    await prefs.setString(
      "customerEmail",
      login.customer.email ?? "",
    );
  }

  // ============================================================
  // OLD SIGNUP
  // ============================================================

  Future<LoginResponse> signup({
    required String name,
    required String? email,
    required String phone,
    required String password,
  }) async {
    await _dio.post(
      "/customer-auth/signup",
      data: {
        "name": name,
        "email": email,
        "mobile": phone,
        "password": password,
      },
    );

    return await login(
      email: email,
      password: password,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
  
    await prefs.clear();
  }

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    print("=================================");
  print("SAVED TOKEN: $token");
  print("=================================");

  return token != null && token.isNotEmpty;
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("token");
  }
}