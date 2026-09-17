import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class OrderStatusStepperWidget extends StatelessWidget {
  final int currentStep;

  const OrderStatusStepperWidget({required this.currentStep, super.key});

  static const List<Map<String, String>> _steps = [
    {
      'label': 'Order Placed',
      'subtitle': 'We received your order',
      'icon': 'receipt_long_rounded',
    },
    {
      'label': 'Confirmed',
      'subtitle': 'Restaurant accepted',
      'icon': 'check_circle_outline_rounded',
    },
    {
      'label': 'Preparing',
      'subtitle': 'Kitchen is cooking',
      'icon': 'restaurant_rounded',
    },
    {
      'label': 'Out for Delivery',
      'subtitle': 'Driver is on the way',
      'icon': 'delivery_dining_rounded',
    },
    {
      'label': 'Delivered',
      'subtitle': 'Enjoy your meal!',
      'icon': 'celebration_rounded',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...List.generate(_steps.length, (index) {
            final isDone = index < currentStep;
            final isCurrent = index == currentStep;
            final isPending = index > currentStep;

            return _StepRow(
              step: _steps[index],
              isDone: isDone,
              isCurrent: isCurrent,
              isPending: isPending,
              isLast: index == _steps.length - 1,
              index: index,
            );
          }),
        ],
      ),
    );
  }
}

class _StepRow extends StatefulWidget {
  final Map<String, String> step;
  final bool isDone;
  final bool isCurrent;
  final bool isPending;
  final bool isLast;
  final int index;

  const _StepRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isPending,
    required this.isLast,
    required this.index,
  });

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isCurrent) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Color lineColor;
    if (widget.isDone) {
      dotColor = AppTheme.success;
      lineColor = AppTheme.success;
    } else if (widget.isCurrent) {
      dotColor = AppTheme.primary;
      lineColor = AppTheme.outlineLight;
    } else {
      dotColor = AppTheme.outlineLight;
      lineColor = AppTheme.outlineLight;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                // Dot
                widget.isCurrent
                    ? ScaleTransition(
                        scale: _scaleAnim,
                        child: _buildDot(dotColor),
                      )
                    : _buildDot(dotColor),
                // Connector line
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.step['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: widget.isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: widget.isPending
                                ? AppTheme.mutedText
                                : AppTheme.headlineText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.step['subtitle']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isPending
                                ? AppTheme.outlineLight
                                : AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isDone)
                    CustomIconWidget(
                      iconName: 'check_rounded',
                      color: AppTheme.success,
                      size: 18,
                    )
                  else if (widget.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Now',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: widget.isPending
            ? AppTheme.surfaceVariantLight
            : color.withAlpha(38),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: widget.isCurrent ? 2.5 : 1.5),
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: widget.step['icon']!,
          color: widget.isPending ? AppTheme.outlineLight : color,
          size: 14,
        ),
      ),
    );
  }
}
