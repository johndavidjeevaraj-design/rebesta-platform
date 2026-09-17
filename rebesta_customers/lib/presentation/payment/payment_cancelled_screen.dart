import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class PaymentCancelledScreen extends StatelessWidget {
  const PaymentCancelledScreen({
    super.key,
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
                  color: Colors.orange.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 52,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Payment cancelled',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.headlineText,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'No order was placed.\n'
                'Your cart is still saved.',
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
                    HapticFeedback.mediumImpact();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Return to Checkout',
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