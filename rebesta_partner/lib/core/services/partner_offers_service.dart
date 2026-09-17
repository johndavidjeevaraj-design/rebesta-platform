import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import 'partner_auth_service.dart';

class PartnerOffersService {
  // ============================================================
  // GET PARTNER OFFERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getPartnerOffers() async {
    final token = await PartnerAuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    debugPrint('================================');
    debugPrint('🎁 GET PARTNER OFFERS');
    debugPrint('================================');

    final response = await ApiClient.get(
      '/coupons/partner',
    );

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('================================');

    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load offers',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid offers response',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Failed to load offers',
      );
    }

    final offers = decoded['offers'];

    if (offers is! List) {
      return [];
    }

    return offers
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  // ============================================================
  // CREATE PARTNER OFFER
  // ============================================================

  static Future<Map<String, dynamic>> createOffer({
    required String code,
    String? title,
    String? description,
    required String discountType,
    required double discountValue,
    double? maxDiscount,
    double? minOrderAmount,
    int? usageLimit,
    String? startsAt,
    String? expiresAt,
    bool freeDelivery = false,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'freeDelivery': freeDelivery,
    };

    if (title != null && title.trim().isNotEmpty) {
      body['title'] = title.trim();
    }

    if (description != null &&
        description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }

    if (maxDiscount != null) {
      body['maxDiscount'] = maxDiscount;
    }

    if (minOrderAmount != null) {
      body['minOrderAmount'] = minOrderAmount;
    }

    if (usageLimit != null) {
      body['usageLimit'] = usageLimit;
    }

    if (startsAt != null &&
        startsAt.trim().isNotEmpty) {
      body['startsAt'] = startsAt;
    }

    if (expiresAt != null &&
        expiresAt.trim().isNotEmpty) {
      body['expiresAt'] = expiresAt;
    }

    debugPrint('================================');
    debugPrint('➕ CREATE PARTNER OFFER');
    debugPrint(
      'Body: ${jsonEncode(body)}',
    );
    debugPrint('================================');

    final response = await ApiClient.post(
      '/coupons/partner',
      body: jsonEncode(body),
    );

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('================================');

    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        decoded is Map
            ? decoded['message']?.toString() ??
                'Failed to create offer'
            : 'Failed to create offer',
      );
    }

    if (decoded is! Map) {
      throw Exception(
        'Invalid create offer response',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  // ============================================================
  // UPDATE PARTNER OFFER
  // ============================================================

  static Future<Map<String, dynamic>> updateOffer({
    required String id,
    String? code,
    String? title,
    String? description,
    String? discountType,
    double? discountValue,
    double? maxDiscount,
    double? minOrderAmount,
    int? usageLimit,
    bool? freeDelivery,
    bool? isActive,
    String? startsAt,
    String? expiresAt,
  }) async {
    final body = <String, dynamic>{};

    if (code != null) {
      body['code'] = code;
    }

    if (title != null) {
      body['title'] = title;
    }

    if (description != null) {
      body['description'] = description;
    }

    if (discountType != null) {
      body['discountType'] = discountType;
    }

    if (discountValue != null) {
      body['discountValue'] = discountValue;
    }

    if (maxDiscount != null) {
      body['maxDiscount'] = maxDiscount;
    }

    if (minOrderAmount != null) {
      body['minOrderAmount'] = minOrderAmount;
    }

    if (usageLimit != null) {
      body['usageLimit'] = usageLimit;
    }

    if (freeDelivery != null) {
      body['freeDelivery'] = freeDelivery;
    }

    if (isActive != null) {
      body['isActive'] = isActive;
    }

    if (startsAt != null) {
      body['startsAt'] = startsAt;
    }

    if (expiresAt != null) {
      body['expiresAt'] = expiresAt;
    }

    debugPrint('================================');
    debugPrint('✏️ UPDATE PARTNER OFFER');
    debugPrint('Offer ID: $id');
    debugPrint(
      'Body: ${jsonEncode(body)}',
    );
    debugPrint('================================');

    final response = await ApiClient.patch(
      '/coupons/partner/$id',
      body: jsonEncode(body),
    );

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('================================');

    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        decoded is Map
            ? decoded['message']?.toString() ??
                'Failed to update offer'
            : 'Failed to update offer',
      );
    }

    if (decoded is! Map) {
      throw Exception(
        'Invalid update offer response',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  // ============================================================
  // DEACTIVATE PARTNER OFFER
  // ============================================================

  static Future<void> deactivateOffer(
    String id,
  ) async {
    debugPrint('================================');
    debugPrint('🗑️ DEACTIVATE PARTNER OFFER');
    debugPrint('Offer ID: $id');
    debugPrint('================================');

    final response = await ApiClient.delete(
      '/coupons/partner/$id',
    );

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('================================');

    if (response.statusCode == 401) {
      await PartnerAuthService.logout();

      throw Exception(
        'Partner session expired. Please login again.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        decoded is Map
            ? decoded['message']?.toString() ??
                'Failed to deactivate offer'
            : 'Failed to deactivate offer',
      );
    }
  }
}