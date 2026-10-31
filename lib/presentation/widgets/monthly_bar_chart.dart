import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/stats_range.dart';

/// Bar chart of income (green) and expense (red) for each month. Tapping a bar shows its amount.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.totals,
    this.compactLabels = false,
  });

  final List<MonthTotals> totals;

  /// With many months (12 in a year), label with just the number and omit the month word.
  final bool compactLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barWidth = compactLabels ? 7.0 : 12.0;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.outlineVariant,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= totals.length) {
                          return const SizedBox.shrink();
                        }
                        final m = totals[i].month.month;
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            compactLabels ? '$m' : '$m月',
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? '收入' : '支出';
                      return BarTooltipItem(
                        '$label ${formatCents((rod.toY * 100).round())}',
                        TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < totals.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: totals[i].income / 100,
                          color: AppTheme.income,
                          width: barWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: totals[i].expense / 100,
                          color: AppTheme.expense,
                          width: barWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: AppTheme.income, label: '收入'),
            SizedBox(width: 16),
            _Legend(color: AppTheme.expense, label: '支出'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
