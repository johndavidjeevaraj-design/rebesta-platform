import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/network/session.dart';
import '../models/customer.dart';

class ProfileService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(authExpiredInterceptor());

  Future<Customer> getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await _dio.get(
      '/customer-auth/profile',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid profile response');
    }

    final customerData = responseData['customer'];

    if (customerData is! Map<String, dynamic>) {
      throw Exception('Customer data missing from profile response');
    }

    return Customer.fromJson(customerData);
  }

  // ============================================================
  // UPDATE PROFILE (name only - mobile is the login identity)
  // ============================================================

  Future<Customer> updateProfile({
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await _dio.patch(
      '/customer-auth/profile',
      data: {
        'name': name,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid profile response');
    }

    final customerData = responseData['customer'];

    if (customerData is! Map<String, dynamic>) {
      throw Exception(
        'Customer data missing from profile response',
      );
    }

    return Customer.fromJson(customerData);
  }
}