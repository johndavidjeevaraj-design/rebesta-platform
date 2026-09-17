import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../models/address.dart';

class AddressService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Customer is not logged in');
    }

    return token;
  }

  // ============================================================
  // GET CUSTOMER ADDRESSES
  // ============================================================

  Future<List<Address>> getAddresses() async {
    final token = await _getToken();

    final response = await _dio.get(
      '/addresses',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.data is! List) {
      throw Exception(
        'Invalid address response from server',
      );
    }

    final List data = response.data as List;

    return data
        .map(
          (e) => Address.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ============================================================
  // SAVE ADDRESS
  // ============================================================

  Future<Address?> saveAddress({
    required String title,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getToken();

    print('SAVING ADDRESS');
    print('TOKEN EXISTS: ${token.isNotEmpty}');

    final response = await _dio.post(
      '/addresses',
      data: {
        'title': title,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    print('SAVE ADDRESS RESPONSE: ${response.data}');

    if (response.data is Map) {
      return Address.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    }

    return null;
  }

  // ============================================================
  // UPDATE ADDRESS
  // ============================================================

  Future<Address?> updateAddress({
    required String addressId,
    required String title,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getToken();

    final response = await _dio.patch(
      '/addresses/$addressId',
      data: {
        'title': title,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.data is Map) {
      return Address.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    }

    return null;
  }

  // ============================================================
  // DELETE ADDRESS
  // ============================================================

  Future<void> deleteAddress({
    required String addressId,
  }) async {
    final token = await _getToken();

    await _dio.delete(
      '/addresses/$addressId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}