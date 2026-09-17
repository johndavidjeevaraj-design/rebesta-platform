import 'package:flutter/material.dart';

class HomeMainFiltersWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const HomeMainFiltersWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const List<_FilterItem> _filters = [
    _FilterItem(
      label: 'Popular',
      icon: Icons.local_fire_department_rounded,
    ),
    _FilterItem(
      label: 'Offers',
      icon: Icons.percent_rounded,
    ),
    _FilterItem(
      label: 'Fast Delivery',
      icon: Icons.bolt_rounded,
    ),
    _FilterItem(
      label: 'Top Rated',
      icon: Icons.star_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,

              // More vertical side / less horizontal bulk
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 7,
              ),

              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF7A3D),
                          Color(0xFFFF4F2F),
                        ],
                      )
                    : null,

                color: selected ? null : Colors.white,

                borderRadius: BorderRadius.circular(18),

                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Colors.grey.shade200,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: selected ? 0.08 : 0.045,
                    ),
                    blurRadius: selected ? 10 : 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: 15,
                    color: selected
                        ? Colors.white
                        : const Color(0xFFFF6538),
                  ),

                  const SizedBox(width: 5),

                  Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF202635),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterItem {
  final String label;
  final IconData icon;

  const _FilterItem({
    required this.label,
    required this.icon,
  });
}