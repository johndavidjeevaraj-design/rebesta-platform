import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Payment successful!',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.headlineText,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Your order has been placed successfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.go(
                      AppRoutes.orderTrackingScreen,
                      extra: orderId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Track Order',
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}