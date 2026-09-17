import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class HomeGreetingWidget extends StatelessWidget {
  final String customerName;

  final bool vegOnly;
  final ValueChanged<bool> onVegChanged;

  const HomeGreetingWidget({
    super.key,
    required this.customerName,
    required this.vegOnly,
    required this.onVegChanged,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  color: AppTheme.mutedText,
                ),
          ),

          const SizedBox(height: 2),

          Text(
            '$customerName 👋',
            style: Theme.of(context)
                .textTheme
                .headlineLarge,
          ),

          const SizedBox(height: 10),

          // =====================================================
          // SEARCH + VEG MODE
          // =====================================================

          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),

                CustomIconWidget(
                  iconName: 'search_rounded',
                  color: AppTheme.headlineText,
                  size: 21,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO:
                      // Open search screen
                    },
                    child: Text(
                      'Search for food or restaurants',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: AppTheme.mutedText,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ),

                // =================================================
                // VEG MODE
                // =================================================

                GestureDetector(
                  onTap: () {
                    onVegChanged(!vegOnly);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 220,
                    ),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(
                      right: 7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: vegOnly
                          ? const Color(0xFFE8F8EC)
                          : const Color(0xFFF7F7F7),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: vegOnly
                            ? const Color(0xFF22A447)
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  const Color(0xFF22A447),
                              width: 1.8,
                            ),
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration:
                                  const BoxDecoration(
                                color:
                                    Color(0xFF22A447),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          'Veg',
                          style: TextStyle(
                            color: vegOnly
                                ? const Color(0xFF168534)
                                : AppTheme.bodyText,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}