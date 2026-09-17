import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeType { success, warning, error, info, neutral }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final BadgeType type;
  final double fontSize;

  const StatusBadgeWidget({
    required this.label,
    this.type = BadgeType.neutral,
    this.fontSize = 11,
    super.key,
  });

  Color _bgColor() {
    switch (type) {
      case BadgeType.success:
        return AppTheme.successContainer;
      case BadgeType.warning:
        return AppTheme.warningContainer;
      case BadgeType.error:
        return const Color(0xFFFEE2E2);
      case BadgeType.info:
        return AppTheme.secondaryContainer;
      case BadgeType.neutral:
        return AppTheme.surfaceVariantLight;
    }
  }

  Color _textColor() {
    switch (type) {
      case BadgeType.success:
        return const Color(0xFF16A34A);
      case BadgeType.warning:
        return const Color(0xFFB45309);
      case BadgeType.error:
        return AppTheme.errorColor;
      case BadgeType.info:
        return AppTheme.secondary;
      case BadgeType.neutral:
        return AppTheme.bodyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: _textColor(),
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
