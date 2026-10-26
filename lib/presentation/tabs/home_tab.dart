import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/transaction_form_page.dart';
import 'package:hello_ledger/presentation/widgets/expense_breakdown.dart';
import 'package:hello_ledger/presentation/widgets/month_selector.dart';
import 'package:hello_ledger/presentation/widgets/month_summary.dart';
import 'package:hello_ledger/presentation/widgets/transaction_tile.dart';

/// 首頁：總資產、當月收支、簡單的支出圓餅圖、依日期分組的交易。
/// 詳細的類別資料在「統計」分頁，由 [onOpenStats] 切過去。
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.onOpenStats});

  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final allAccounts = ref.watch(allAccountsProvider).value ?? [];
    final balances = ref.watch(balancesProvider);
    final stats = ref.watch(monthlyStatsProvider);
    final month = ref.watch(selectedMonthProvider);

    final total = balances.values.fold<int>(0, (sum, v) => sum + v);
    final accountNames = {for (final a in allAccounts) a.id: a.name};
    final categoryById = {for (final c in categories) c.id: c};

    // 依日期分組，保持新的在前面
    final days = <DateTime, List<TransactionRecord>>{};
    for (final t in stats.txs) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      days.putIfAbsent(day, () => []).add(t);
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        // 總資產
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '總資產',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCents(total),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),

        const MonthSelector(),
        MonthSummary(stats: stats),

        // 支出圓餅圖（只有圖，詳細資料到「統計」分頁看）
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('支出類別', style: theme.textTheme.titleMedium),
              IconButton(
                tooltip: '查看詳細統計',
                icon: const Icon(Icons.bar_chart),
                onPressed: onOpenStats,
              ),
            ],
          ),
        ),
        ExpenseBreakdown(
          key: ValueKey(month), // 換月份時重置選取狀態
          rows: stats.categoryRows,
          total: stats.expense,
          categories: categories,
        ),

        // 每日交易
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 4),
          child: Text('交易紀錄', style: theme.textTheme.titleMedium),
        ),
        if (days.isEmpty)
          const Card(child: ListTile(title: Text('這個月還沒有交易')))
        else
          for (final entry in days.entries) ...[
            _DayHeader(day: entry.key, txs: entry.value),
            for (final t in entry.value)
              TransactionTile(
                tx: t,
                title: t.type == TransactionType.transfer
                    ? '轉帳：${accountNames[t.accountId] ?? '?'} → ${accountNames[t.toAccountId] ?? '?'}'
                    : categoryById[t.categoryId]?.name ?? '未分類',
                icon: t.type == TransactionType.transfer
                    ? Icons.swap_horiz
                    : categoryIcon(categoryById[t.categoryId]),
                accountName: accountNames[t.accountId] ?? '?',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionFormPage(existing: t),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

/// 每天的標題：日期、星期，以及當天的結餘（收入減支出）。
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.txs});

  final DateTime day;
  final List<TransactionRecord> txs;

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    var balance = 0;
    for (final t in txs) {
      if (t.type == TransactionType.income) balance += t.amount;
      if (t.type == TransactionType.expense) balance -= t.amount;
    }

    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${day.month}月${day.day}日 週${_weekdays[day.weekday - 1]}',
            style: style?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '結餘 ${formatCents(balance)}',
            style: style?.copyWith(color: AppTheme.balanceColor(balance)),
          ),
        ],
      ),
    );
  }
}
