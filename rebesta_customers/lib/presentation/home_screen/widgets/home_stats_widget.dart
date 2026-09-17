import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class HomeStatsWidget extends StatefulWidget {
  const HomeStatsWidget({super.key});

  @override
  State<HomeStatsWidget> createState() => _HomeStatsWidgetState();
}

class _HomeStatsWidgetState extends State<HomeStatsWidget> {
  int _selectedPeriod = 0; // 0=This Week, 1=This Month
  final List<String> _periods = ['This Week', 'This Month'];

  // Orders per day this week (Mon–Sun)
  final List<double> _weeklyOrders = [1, 0, 2, 1, 3, 2, 1];
  // Orders per week this month (W1–W4)
  final List<double> _monthlyOrders = [5, 8, 6, 9];

  List<double> get _activeData =>
      _selectedPeriod == 0 ? _weeklyOrders : _monthlyOrders;

  List<String> get _labels => _selectedPeriod == 0
      ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
      : ['W1', 'W2', 'W3', 'W4'];

  @override
  Widget build(BuildContext context) {
    final totalOrders = _activeData.reduce((a, b) => a + b).toInt();
    final totalSpend = totalOrders * 16.40;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your Stats',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    setState(() => _selectedPeriod = (_selectedPeriod + 1) % 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _periods[_selectedPeriod],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.bodyText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      CustomIconWidget(
                        iconName: 'keyboard_arrow_down_rounded',
                        color: AppTheme.bodyText,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Summary row
          Row(
            children: [
              _StatPill(
                icon: 'receipt_long_rounded',
                label: 'Orders',
                value: '$totalOrders',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _StatPill(
                icon: 'payments_rounded',
                label: 'Spent',
                value: '\$${totalSpend.toStringAsFixed(0)}',
                color: AppTheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bar chart
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_activeData.reduce((a, b) => a > b ? a : b) + 1),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} order${rod.toY.toInt() == 1 ? '' : 's'}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _labels[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.outlineLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  _activeData.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _activeData[i],
                        color:
                            _activeData[i] ==
                                _activeData.reduce((a, b) => a > b ? a : b)
                            ? AppTheme.headlineText
                            : AppTheme.secondary.withAlpha(128),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(iconName: icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.headlineText,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
