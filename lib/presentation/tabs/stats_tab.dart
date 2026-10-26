import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/widgets/expense_breakdown.dart';
import 'package:hello_ledger/presentation/widgets/month_comparison.dart';
import 'package:hello_ledger/presentation/widgets/month_selector.dart';
import 'package:hello_ledger/presentation/widgets/month_summary.dart';

/// 統計分頁：當月收支、和上個月的比較、支出圓餅圖與完整的類別明細。
class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthlyStatsProvider);
    final previous = ref.watch(previousMonthlyStatsProvider);
    final month = ref.watch(selectedMonthProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const MonthSelector(),
        MonthSummary(stats: stats),
        MonthComparison(month: month, current: stats, previous: previous),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
          child: Text('支出類別', style: Theme.of(context).textTheme.titleMedium),
        ),
        ExpenseBreakdown(
          key: ValueKey(month),
          rows: stats.categoryRows,
          total: stats.expense,
          categories: categories,
          showList: true,
          // 上個月完全沒有紀錄就不顯示比較，避免每個類別都標「新增」
          previousByCategory: previous.txs.isEmpty
              ? null
              : {for (final r in previous.categoryRows) r.key: r.value},
        ),
      ],
    );
  }
}
