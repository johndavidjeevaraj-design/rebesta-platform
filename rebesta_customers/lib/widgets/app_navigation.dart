import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import './custom_icon_widget.dart';

// TODO: Replace with [Riverpod/Bloc] for production state management

class _TabSpec {
  final String label;
  final String icon;
  final String selectedIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Home',
      icon: 'home_outlined',
      selectedIcon: 'home_rounded',
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Search',
      icon: 'search_rounded',
      selectedIcon: 'search_rounded',
      branchIndex: null, // stub
    ),
    _TabSpec(
      label: 'Orders',
      icon: 'receipt_long_outlined',
      selectedIcon: 'receipt_long_rounded',
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Profile',
      icon: 'person_outline_rounded',
      selectedIcon: 'person_rounded',
      branchIndex: null, // stub
    ),
  ];

  void _onTabTap(int visualIndex) {
    final tab = _tabs[visualIndex];
    if (tab.branchIndex == null) return; // stub — silent ignore
    setState(() => _selectedVisualIndex = visualIndex);
    widget.navigationShell.goBranch(
      tab.branchIndex!,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync visual index with shell
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].branchIndex == widget.navigationShell.currentIndex) {
        _selectedVisualIndex = i;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppTheme.pillNavShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final isActive = i == _selectedVisualIndex;
            final isStub = tab.branchIndex == null;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onTabTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isStub ? 0.4 : 1.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary.withAlpha(31)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomIconWidget(
                          iconName: isActive ? tab.selectedIcon : tab.icon,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.mutedText,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.mutedText,
                        ),
                        child: Text(tab.label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
