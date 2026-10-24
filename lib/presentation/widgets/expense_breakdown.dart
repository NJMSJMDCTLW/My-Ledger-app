import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';

/// 支出類別的圓餅圖。[showList] 為 true 時，下方多一份詳細的類別清單。
/// [rows] 是（類別 id，金額），要先由大到小排好。
class ExpenseBreakdown extends StatefulWidget {
  const ExpenseBreakdown({
    super.key,
    required this.rows,
    required this.total,
    required this.categories,
    this.showList = false,
  });

  final List<MapEntry<int?, int>> rows;
  final int total;
  final List<Category> categories;
  final bool showList;

  @override
  State<ExpenseBreakdown> createState() => _ExpenseBreakdownState();
}

class _ExpenseBreakdownState extends State<ExpenseBreakdown> {
  int? _touched; // 被點到的區塊

  String? _nameOf(int? id) {
    for (final c in widget.categories) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = widget.rows;
    final total = widget.total;
    final touched =
        (_touched != null && _touched! < rows.length) ? rows[_touched!] : null;

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('這個月沒有支出')),
      );
    }

    return Column(
      children: [
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
                        // 太小的區塊不放文字，避免擠在一起
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
              // 圓心：預設顯示總支出，點某個區塊就顯示該類別
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
          for (var i = 0; i < rows.length; i++)
            Card(
              color: i == _touched
                  ? AppTheme.categoryColor(rows[i].key).withValues(alpha: 0.35)
                  : null,
              child: ListTile(
                onTap: () =>
                    setState(() => _touched = i == _touched ? null : i),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.categoryColor(rows[i].key),
                  foregroundColor: AppTheme.onMacaron,
                  child: Icon(categoryIcon(_nameOf(rows[i].key)), size: 20),
                ),
                title: Text(_nameOf(rows[i].key) ?? '未分類'),
                subtitle: Text(
                    '${(rows[i].value / total * 100).toStringAsFixed(1)}%'),
                trailing: Text(formatCents(rows[i].value)),
              ),
            ),
      ],
    );
  }
}
