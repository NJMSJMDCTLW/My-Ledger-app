import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/presentation/widgets/delta_text.dart';

/// 支出類別的圓餅圖。[showList] 為 true 時，下方多一份詳細的類別清單。
/// [rows] 是（類別 id，金額），要先由大到小排好。
///
/// 給了 [previousByCategory]（上個月各類別的支出）時，清單每個類別會顯示和上個月的比較，
/// 上個月有花、這個月完全沒花的類別也會列在最後面。
class ExpenseBreakdown extends StatefulWidget {
  const ExpenseBreakdown({
    super.key,
    required this.rows,
    required this.total,
    required this.categories,
    this.showList = false,
    this.previousByCategory,
  });

  final List<MapEntry<int?, int>> rows;
  final int total;
  final List<Category> categories;
  final bool showList;
  final Map<int?, int>? previousByCategory;

  @override
  State<ExpenseBreakdown> createState() => _ExpenseBreakdownState();
}

class _ExpenseBreakdownState extends State<ExpenseBreakdown> {
  int? _touched; // 被點到的區塊

  Category? _categoryOf(int? id) {
    for (final c in widget.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? _nameOf(int? id) => _categoryOf(id)?.name;

  /// 清單用的列：這個月有花的類別，加上「上個月有花、這個月沒花」的類別（金額 0）。
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

    // 沒有任何可顯示的東西（這個月沒花錢，也沒有要比較的上月類別）
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
