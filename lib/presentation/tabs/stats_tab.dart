import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/widgets/expense_breakdown.dart';
import 'package:hello_ledger/presentation/widgets/month_selector.dart';
import 'package:hello_ledger/presentation/widgets/month_summary.dart';

/// 統計分頁：當月支出圓餅圖加上完整的類別明細。
class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthlyStatsProvider);
    final month = ref.watch(selectedMonthProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const MonthSelector(),
        MonthSummary(stats: stats),
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
        ),
      ],
    );
  }
}
