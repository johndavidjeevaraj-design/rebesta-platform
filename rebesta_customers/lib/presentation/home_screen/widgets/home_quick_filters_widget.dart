import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class HomeQuickFiltersWidget extends StatelessWidget {
  final bool vegOnly;
  final ValueChanged<bool> onVegChanged;

  const HomeQuickFiltersWidget({
    super.key,
    required this.vegOnly,
    required this.onVegChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              onVegChanged(!vegOnly);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: vegOnly
                    ? const Color(0xffE8F8EC)
                    : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: vegOnly
                      ? const Color(0xff22A447)
                      : Colors.grey.shade200,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: vegOnly
                          ? const Color(0xff22A447)
                          : Colors.white,
                      border: Border.all(
                        color: const Color(0xff22A447),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: vegOnly
                        ? const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),

                  const SizedBox(width: 7),

                  Text(
                    'Veg Only',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: vegOnly
                          ? const Color(0xff168A38)
                          : AppTheme.headlineText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          _FilterPill(
            icon: Icons.bolt_rounded,
            label: 'Fast Delivery',
            onTap: () {},
          ),

          const SizedBox(width: 8),

          _FilterPill(
            icon: Icons.star_rounded,
            label: 'Top Rated',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.headlineText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}