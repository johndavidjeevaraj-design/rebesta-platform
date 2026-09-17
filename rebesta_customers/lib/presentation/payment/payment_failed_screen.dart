import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class PaymentFailedScreen extends StatelessWidget {
  final String message;

  const PaymentFailedScreen({
    super.key,
    this.message = 'Your payment could not be completed.',
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
                  color: Colors.red.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 60,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Payment failed',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.headlineText,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '$message\n\nYour order has NOT been placed. '
                'Your cart is still safe.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Try Payment Again',
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