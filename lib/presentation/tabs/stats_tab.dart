import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/stats_range.dart';
import 'package:hello_ledger/presentation/widgets/expense_breakdown.dart';
import 'package:hello_ledger/presentation/widgets/month_summary.dart';
import 'package:hello_ledger/presentation/widgets/monthly_bar_chart.dart';
import 'package:hello_ledger/presentation/widgets/period_comparison.dart';
import 'package:hello_ledger/presentation/widgets/period_selector.dart';

/// 統計分頁：可以看每月、近六個月、一年。
/// 內容有收支總覽、每月長條圖（多個月才有）、和上一期的比較、支出圓餅圖與類別明細。
class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final range = ref.watch(statsRangeProvider);
    final stats = ref.watch(periodStatsProvider);
    final previous = ref.watch(previousPeriodStatsProvider);
    final totals = ref.watch(periodMonthlyTotalsProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final theme = Theme.of(context);

    final isMultiMonth = period != StatsPeriod.month;
    final months = elapsedMonthCount(range, DateTime.now());

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const PeriodSelector(),
        MonthSummary(stats: stats),

        // 多個月才有：每月平均與長條圖
        if (isMultiMonth) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('平均每月支出', style: theme.textTheme.bodySmall),
                        Text(
                          formatCents((stats.expense / months).round()),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('平均每月收入', style: theme.textTheme.bodySmall),
                        Text(
                          formatCents((stats.income / months).round()),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            child: Text('每月收支', style: theme.textTheme.titleMedium),
          ),
          MonthlyBarChart(
            totals: totals,
            compactLabels: period == StatsPeriod.year,
          ),
        ],

        PeriodComparison(
          title: _comparisonTitle(period, range),
          previousName: period.previousName,
          current: stats,
          previous: previous,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
          child: Text('支出類別', style: theme.textTheme.titleMedium),
        ),
        ExpenseBreakdown(
          key: ValueKey((period, range.start)),
          rows: stats.categoryRows,
          total: stats.expense,
          categories: categories,
          showList: true,
          // 上一期完全沒有紀錄就不顯示類別比較，避免每個類別都標「新增」
          previousByCategory: previous.txs.isEmpty
              ? null
              : {for (final r in previous.categoryRows) r.key: r.value},
          previousName: period.previousName,
        ),
      ],
    );
  }

  static String _comparisonTitle(StatsPeriod period, StatsRange range) {
    final prevStart = range.previousStart;
    // previousEnd 不含，所以上一期的最後一個月是它的前一個月
    final prevLast = DateTime(range.previousEnd.year, range.previousEnd.month - 1);
    return switch (period) {
      StatsPeriod.month => '與上個月比較（${prevStart.month} 月）',
      StatsPeriod.sixMonths => '與前六個月比較'
          '（${prevStart.year}/${prevStart.month} – ${prevLast.year}/${prevLast.month}）',
      StatsPeriod.year => '與去年比較（${prevStart.year} 年）',
    };
  }
}
