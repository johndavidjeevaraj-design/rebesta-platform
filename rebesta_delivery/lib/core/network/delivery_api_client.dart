import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/delivery_auth_storage.dart';

class DeliveryApiClient {
  DeliveryApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<Options> authOptions() async {
    final token =
        await DeliveryAuthStorage.getToken();

    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );
  }
}