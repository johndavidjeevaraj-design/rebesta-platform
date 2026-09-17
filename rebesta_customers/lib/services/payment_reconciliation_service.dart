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

      debugPrint(
        '========================================',
      );
      debugPrint(
        'PENDING PAYMENT FOUND',
      );
      debugPrint(
        'Razorpay Order: $pendingOrderId',
      );
      debugPrint(
        'RECONCILING PAYMENT',
      );
      debugPrint(
        '========================================',
      );

      final result =
          await _paymentService.reconcilePayment(
        pendingOrderId,
      );

      debugPrint(
        'RECONCILE RESULT: $result',
      );

      return result;
    } catch (e, stackTrace) {
      debugPrint(
        'PAYMENT RECONCILIATION ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      // Do NOT delete the pending payment here.
      //
      // If the network failed, we want another app-open
      // attempt to reconcile it.
      return null;
    }
  }
}