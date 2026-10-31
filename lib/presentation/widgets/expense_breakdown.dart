import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/presentation/widgets/delta_text.dart';

/// Pie chart of expense categories. When [showList] is true, a detailed category list follows below.
/// [rows] are (category id, amount) and must already be sorted from largest to smallest.
///
/// When [previousByCategory] (last period's expense per category) is given, each category in the list shows its comparison with that period,
/// and categories with spending last period but none this period are listed at the end.
class ExpenseBreakdown extends StatefulWidget {
  const ExpenseBreakdown({
    super.key,
    required this.rows,
    required this.total,
    required this.categories,
    this.showList = false,
    this.previousByCategory,
    this.previousName = '上月',
  });

  final List<MapEntry<int?, int>> rows;
  final int total;
  final List<Category> categories;
  final bool showList;
  final Map<int?, int>? previousByCategory;

  /// Name of the comparison target, e.g. "last month", "the previous six months", "last year".
  final String previousName;

  @override
  State<ExpenseBreakdown> createState() => _ExpenseBreakdownState();
}

class _ExpenseBreakdownState extends State<ExpenseBreakdown> {
  int? _touched; // the section that was tapped

  Category? _categoryOf(int? id) {
    for (final c in widget.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? _nameOf(int? id) => _categoryOf(id)?.name;

  /// Rows for the list: categories with spending this period, plus categories with spending last period but none this period (amount 0).
  List<MapEntry<int?, int>> get _listRows {
    final prev = widget.previousByCategory;
    if (prev == null) return widget.rows;

    final thisMonth = widget.rows.map((r) => r.key).toSet();
    final missing = prev.entries
        .where((e) => !thisMonth.contains(e.key) && e.value > 0)
        .map((e) => MapEntry<int?, int>(e.key, 0))
        .toList()
      ..sort((a, b) => prev[b.key]!.compareTo(prev[a.key]!));
    return [...widget.rows, ...missing];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = widget.rows;
    final listRows = _listRows;
    final total = widget.total;
    final prev = widget.previousByCategory;
    final touched =
        (_touched != null && _touched! < rows.length) ? rows[_touched!] : null;

    // Nothing to show at all (no spending this period and no previous-period categories to compare)
    if (rows.isEmpty && !(widget.showList && listRows.isNotEmpty)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('這個月沒有支出')),
      );
    }

    return Column(
      children: [
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('這個月沒有支出')),
          )
        else
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 70,
                    sections: [
                      for (var i = 0; i < rows.length; i++)
                        PieChartSectionData(
                          value: rows[i].value.toDouble(),
                          color: AppTheme.categoryColor(rows[i].key),
                          radius: i == _touched ? 52 : 44,
                          // no text on very small sections, to avoid crowding
                          title: rows[i].value / total >= 0.06
                              ? '${(rows[i].value / total * 100).round()}%'
                              : '',
                          titleStyle: const TextStyle(
                            color: AppTheme.onMacaron,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                    ],
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions) return;
                        final index =
                            response?.touchedSection?.touchedSectionIndex;
                        setState(() => _touched =
                            (index == null || index < 0) ? null : index);
                      },
                    ),
                  ),
                ),
                // Center: shows the total expense by default, or that category when a section is tapped
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        touched == null
                            ? '總支出'
                            : _nameOf(touched.key) ?? '未分類',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        formatCents(touched?.value ?? total),
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (widget.showList)
          for (var i = 0; i < listRows.length; i++)
            Card(
              color: i == _touched
                  ? AppTheme.categoryColor(listRows[i].key)
                      .withValues(alpha: 0.35)
                  : null,
              child: ListTile(
                onTap: i < rows.length
                    ? () => setState(() => _touched = i == _touched ? null : i)
                    : null,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.categoryColor(listRows[i].key),
                  foregroundColor: AppTheme.onMacaron,
                  child: Icon(categoryIcon(_categoryOf(listRows[i].key)),
                      size: 20),
                ),
                title: Text(_nameOf(listRows[i].key) ?? '未分類'),
                subtitle: Text(
                  total == 0
                      ? '—'
                      : '${(listRows[i].value / total * 100).toStringAsFixed(1)}%',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatCents(listRows[i].value)),
                    if (prev != null)
                      DeltaText(
                        current: listRows[i].value,
                        previous: prev[listRows[i].key] ?? 0,
                        higherIsBad: true,
                        previousName: widget.previousName,
                        noPreviousLabel: '新增',
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
