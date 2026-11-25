import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/network/session.dart';

class PaymentService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(authExpiredInterceptor());

  static const String _pendingPaymentKey =
      'rebesta_pending_cashfree_order_id';

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // CREATE CHECKOUT PAYMENT
  // ============================================================

  Future<Map<String, dynamic>> createCheckoutPayment({
    required String? addressId,
    required String restaurantPartnerId,
    required String orderType,
    String? couponCode,
  }) async {
    final response = await _dio.post(
      '/payments/create-order',
      data: {
        'addressId': addressId,
        'restaurantPartnerId': restaurantPartnerId,
        'orderType': orderType,
        if (couponCode != null && couponCode.isNotEmpty)
          'couponCode': couponCode,
      },
      options: Options(
        headers: await _authHeaders(),
      ),
    );

    final result = Map<String, dynamic>.from(response.data);

    final cashfreeOrderId = result['orderId']?.toString();

    if (cashfreeOrderId != null && cashfreeOrderId.isNotEmpty) {
      await savePendingPayment(cashfreeOrderId);
    }

    return result;
  }

  // ============================================================
  // VERIFY PAYMENT
  // ============================================================

  Future<Map<String, dynamic>> verifyPayment({
    required String cashfreeOrderId,
  }) async {
    final response = await _dio.post(
      '/payments/verify',
      data: {'cashfreeOrderId': cashfreeOrderId},
      options: Options(headers: await _authHeaders()),
    );
    final result = Map<String, dynamic>.from(response.data);
    if (result['success'] == true) await clearPendingPayment();
    return result;
  }

  Future<Map<String, dynamic>> reconcilePayment(String cashfreeOrderId) async {
    final response = await _dio.post(
      '/payments/reconcile',
      data: {'cashfreeOrderId': cashfreeOrderId},
      options: Options(headers: await _authHeaders()),
    );
    final result = Map<String, dynamic>.from(response.data);
    final state = result['state']?.toString();
    if (state == 'confirmed' || state == 'failed') await clearPendingPayment();
    return result;
  }

  // ============================================================
  // PENDING PAYMENT STORAGE
  // ============================================================

  Future<void> savePendingPayment(
    String cashfreeOrderId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _pendingPaymentKey,
      cashfreeOrderId,
    );
  }

  Future<String?> getPendingPayment() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _pendingPaymentKey,
    );
  }

  Future<void> clearPendingPayment() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _pendingPaymentKey,
    );
  }
}