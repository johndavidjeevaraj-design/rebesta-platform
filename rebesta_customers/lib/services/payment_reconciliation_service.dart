import 'package:flutter/foundation.dart';

import 'payment_service.dart';

class PaymentReconciliationService {
  final PaymentService _paymentService =
      PaymentService();

  Future<Map<String, dynamic>?> reconcilePendingPayment() async {
    try {
      final pendingOrderId =
          await _paymentService.getPendingPayment();

      if (pendingOrderId == null ||
          pendingOrderId.isEmpty) {
        return null;
      }

      final result =
          await _paymentService.reconcilePayment(
        pendingOrderId,
      );

      return result;
    } catch (_) {
      // Do NOT delete the pending payment here.
      //
      // If the network failed, we want another app-open
      // attempt to reconcile it.
      return null;
    }
  }
}