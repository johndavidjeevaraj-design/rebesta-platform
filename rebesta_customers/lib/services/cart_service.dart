import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

class CartService {
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
  // GET CART
  // ============================================================

// ============================================================
// GET CART
// ============================================================

Future<Map<String, dynamic>> getCart({
  String? restaurantPartnerId,
}) async {
  final token = await _getToken();

  final response = await _dio.get(
    '/cart',
    queryParameters: restaurantPartnerId != null &&
            restaurantPartnerId.isNotEmpty
        ? {
            'restaurantPartnerId': restaurantPartnerId,
          }
        : null,
    options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ),
  );

  if (response.data is! Map) {
    throw Exception('Invalid cart response');
  }

  return Map<String, dynamic>.from(response.data);
}
  // ============================================================
  // ADD ITEM
  // ============================================================

  Future<Map<String, dynamic>> addItem({
    required String menuItemId,
    int quantity = 1,
  }) async {
    final token = await _getToken();

    final response = await _dio.post(
      '/cart/items',
      data: {
        'menuItemId': menuItemId,
        'quantity': quantity,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.data is! Map) {
      throw Exception('Invalid add-to-cart response');
    }

    return Map<String, dynamic>.from(
      response.data,
    );
  }

  // ============================================================
  // UPDATE ITEM QUANTITY
  // ============================================================

  Future<Map<String, dynamic>> updateItem({
    required String cartItemId,
    required int quantity,
  }) async {
    final token = await _getToken();

    if (quantity < 1) {
      throw Exception(
        'Quantity cannot be less than 1',
      );
    }
    

    print('================================');
print('🛒 UPDATE CART ITEM');
print('Cart Item ID: $cartItemId');
print('Quantity: $quantity');
print('Token exists: ${token.isNotEmpty}');
print('Token length: ${token.length}');
print('================================');


    final response = await _dio.patch(
      '/cart/items/$cartItemId',
      data: {
        'quantity': quantity,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.data is! Map) {
      throw Exception(
        'Invalid cart update response',
      );
    }

    return Map<String, dynamic>.from(
      response.data,
    );
  }

  Future<Map<String, dynamic>> removeItem({
  required String cartItemId,
}) async {
  final token = await _getToken();

  final response = await _dio.delete(
    '/cart/items/$cartItemId',
    options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ),
  );

  if (response.data is! Map) {
    throw Exception(
      'Invalid remove-cart-item response',
    );
  }

  return Map<String, dynamic>.from(
    response.data,
  );
}
}