import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/hkd_converter.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/widgets/hkd_note.dart';
import 'package:hello_ledger/presentation/transaction_form_page.dart';
import 'package:hello_ledger/presentation/widgets/expense_breakdown.dart';
import 'package:hello_ledger/presentation/widgets/month_selector.dart';
import 'package:hello_ledger/presentation/widgets/month_summary.dart';
import 'package:hello_ledger/presentation/widgets/transaction_tile.dart';

/// Home: total balance, this month's income and expense, a simple expense pie chart, and transactions grouped by day.
/// The detailed category breakdown is on the "Statistics" tab, reached through [onOpenStats].
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.onOpenStats});

  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final allAccounts = ref.watch(allAccountsProvider).value ?? [];
    final stats = ref.watch(monthlyStatsProvider);
    final month = ref.watch(selectedMonthProvider);
    final converter = ref.watch(hkdConverterProvider);

    // Total balance: each account's balance converted to HKD and summed
    final total = ref.watch(totalAssetsHkdProvider);
    final accountNames = {for (final a in allAccounts) a.id: a.name};
    final categoryById = {for (final c in categories) c.id: c};

    // Group by day, keeping the newest first
    final days = <DateTime, List<TransactionRecord>>{};
    for (final t in stats.txs) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      days.putIfAbsent(day, () => []).add(t);
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        // Total balance
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
                  formatMoney(total, baseCurrency),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        const HkdNote(),

        const MonthSelector(),
        MonthSummary(stats: stats),

        // Expense pie chart (chart only; details are on the "Statistics" tab)
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
          key: ValueKey(month), // reset the selection when the month changes
          rows: stats.categoryRows,
          total: stats.expense,
          categories: categories,
        ),

        // Daily transactions
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 4),
          child: Text('交易紀錄', style: theme.textTheme.titleMedium),
        ),
        if (days.isEmpty)
          const Card(child: ListTile(title: Text('這個月還沒有交易')))
        else
          for (final entry in days.entries) ...[
            _DayHeader(day: entry.key, txs: entry.value, converter: converter),
            for (final t in entry.value)
              TransactionTile(
                tx: t,
                currency: converter.currencyOfAccount(t.accountId),
                hkdAmount: converter.amountOf(t),
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

/// The heading for each day: the date, the weekday, and that day's balance (income minus expense).
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.txs,
    required this.converter,
  });

  final DateTime day;
  final List<TransactionRecord> txs;
  final HkdConverter converter;

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    // Always convert the day's balance to HKD, so transactions in different currencies can be added together
    var balance = 0;
    for (final t in txs) {
      if (t.type == TransactionType.income) balance += converter.amountOf(t);
      if (t.type == TransactionType.expense) balance -= converter.amountOf(t);
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
