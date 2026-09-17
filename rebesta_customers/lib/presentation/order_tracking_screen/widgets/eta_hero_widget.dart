import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class EtaHeroWidget extends StatelessWidget {
  final int currentStep;
  final Animation<double> pulseAnimation;

  const EtaHeroWidget({
    required this.currentStep,
    required this.pulseAnimation,
    super.key,
  });

  String get _statusLabel {
    const labels = [
      'Order Placed',
      'Order Confirmed',
      'Being Prepared',
      'On the Way',
      'Delivered!',
    ];
    return labels[currentStep.clamp(0, 4)];
  }

  String get _etaText {
    if (currentStep == 4) return 'Delivered';
    return '12–18 min';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDelivered = currentStep == 4;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDelivered
              ? [AppTheme.success, const Color(0xFF16A34A)]
              : [AppTheme.primary, AppTheme.primary.withRed(220)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDelivered ? AppTheme.success : AppTheme.primary)
                .withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDelivered ? '🎉 Order Delivered!' : 'Estimated Arrival',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _etaText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Pulse animation on icon
          ScaleTransition(
            scale: pulseAnimation,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: isDelivered
                      ? 'check_circle_rounded'
                      : 'delivery_dining_rounded',
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
