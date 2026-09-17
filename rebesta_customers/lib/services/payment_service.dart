import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

class PaymentService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static const String _pendingPaymentKey =
      'rebesta_pending_razorpay_order_id';

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

    final razorpayOrderId =
        result['orderId']?.toString();

    if (razorpayOrderId != null &&
        razorpayOrderId.isNotEmpty) {
      await savePendingPayment(razorpayOrderId);
    }

    return result;
  }

  // ============================================================
  // VERIFY PAYMENT
  // ============================================================

  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String signature,
  }) async {
    final response = await _dio.post(
      '/payments/verify',
      data: {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'signature': signature,
      },
      options: Options(
        headers: await _authHeaders(),
      ),
    );

    final result =
        Map<String, dynamic>.from(response.data);

    if (result['success'] == true) {
      await clearPendingPayment();
    }

    return result;
  }

  // ============================================================
  // RECONCILE PAYMENT
  //
  // Used when the app was killed / network dropped during
  // payment and we don't know whether Razorpay succeeded.
  // ============================================================

  Future<Map<String, dynamic>> reconcilePayment(
    String razorpayOrderId,
  ) async {
    final response = await _dio.post(
      '/payments/reconcile',
      data: {
        'razorpayOrderId': razorpayOrderId,
      },
      options: Options(
        headers: await _authHeaders(),
      ),
    );

    final result =
        Map<String, dynamic>.from(response.data);

    final state =
        result['state']?.toString();

    if (state == 'confirmed' ||
        state == 'failed') {
      await clearPendingPayment();
    }

    return result;
  }

  // ============================================================
  // PENDING PAYMENT STORAGE
  // ============================================================

  Future<void> savePendingPayment(
    String razorpayOrderId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _pendingPaymentKey,
      razorpayOrderId,
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