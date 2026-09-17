import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class DriverInfoCardWidget extends StatelessWidget {
  final Map<String, dynamic>? rider;
  final Map<String, dynamic>? eta;

  const DriverInfoCardWidget({
    super.key,
    required this.rider,
    this.eta,
  });

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // NO RIDER ASSIGNED YET
    // ----------------------------------------------------------

    if (rider == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'delivery_dining_rounded',
                  color: AppTheme.mutedText,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Waiting for a delivery partner to be assigned...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // REAL RIDER DATA
    // ----------------------------------------------------------

    final name = rider!['name']?.toString() ?? 'Delivery Partner';
    final mobile = rider!['mobile']?.toString();
    final vehicleType = rider!['vehicleType']?.toString();
    final vehicleNumber = rider!['vehicleNumber']?.toString();

    final ratingValue = rider!['rating'];
    final rating = ratingValue is num ? ratingValue.toDouble() : 0.0;

    final totalReviews = rider!['totalReviews'];
    final reviewsCount = totalReviews is num ? totalReviews.toInt() : 0;

    final distanceKm = eta?['distance'];
    final durationMin = eta?['duration'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border(left: BorderSide(color: AppTheme.secondary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your Delivery Partner',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'On the way',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    if (vehicleType != null || vehicleNumber != null)
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'two_wheeler_rounded',
                            color: AppTheme.mutedText,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            [
                              if (vehicleType != null) vehicleType,
                              if (vehicleNumber != null) vehicleNumber,
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'star_rounded',
                          color: AppTheme.warning,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(2) : 'New',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.headlineText,
                          ),
                        ),
                        if (reviewsCount > 0)
                          Text(
                            ' · $reviewsCount deliveries',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _ActionButton(
                    icon: 'call_rounded',
                    color: AppTheme.success,
                    onTap: mobile == null
                        ? null
                        : () {
                            // TODO: launch tel: link with url_launcher
                          },
                  ),
                ],
              ),
            ],
          ),
          if (distanceKm != null || durationMin != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (distanceKm != null)
                    _TrackMetric(
                      icon: 'near_me_rounded',
                      label: 'Distance',
                      value: '${distanceKm.toString()} km',
                    ),
                  if (distanceKm != null && durationMin != null)
                    Container(width: 1, height: 32, color: AppTheme.outlineLight),
                  if (durationMin != null)
                    _TrackMetric(
                      icon: 'schedule_rounded',
                      label: 'ETA',
                      value: '${durationMin.toString()} min',
                      valueColor: AppTheme.primary,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (onTap == null ? Colors.grey : color).withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: onTap == null ? Colors.grey : color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _TrackMetric extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _TrackMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomIconWidget(iconName: icon, color: AppTheme.mutedText, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.headlineText,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
      ],
    );
  }
}