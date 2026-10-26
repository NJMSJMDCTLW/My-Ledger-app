import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/recurring_form_page.dart';

/// 固定收支分頁：每月自動記錄的收入、支出與轉帳。
class RecurringTab extends ConsumerWidget {
  const RecurringTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringRulesProvider).value ?? [];
    final allAccounts = ref.watch(allAccountsProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];
    final converter = ref.watch(hkdConverterProvider);

    if (rules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '還沒有固定收支\n例如每月的房租、薪水，設定一次就會自動記帳',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final accountNames = {for (final a in allAccounts) a.id: a.name};
    final categoryById = {for (final c in categories) c.id: c};

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        for (final r in rules)
          _RuleTile(
            rule: r,
            title: r.type == TransactionType.transfer
                ? '轉帳：${accountNames[r.accountId] ?? '?'} → ${accountNames[r.toAccountId] ?? '?'}'
                : categoryById[r.categoryId]?.name ?? '未分類',
            icon: r.type == TransactionType.transfer
                ? Icons.swap_horiz
                : categoryIcon(categoryById[r.categoryId]),
            accountName: accountNames[r.accountId] ?? '?',
            currency: converter.currencyOfAccount(r.accountId),
          ),
      ],
    );
  }
}

class _RuleTile extends ConsumerWidget {
  const _RuleTile({
    required this.rule,
    required this.title,
    required this.icon,
    required this.accountName,
    required this.currency,
  });

  final RecurringRule rule;
  final String title;
  final IconData icon;
  final String accountName;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTransfer = rule.type == TransactionType.transfer;
    final active = rule.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => RecurringFormPage(existing: rule),
          ),
        ),
        leading: Opacity(
          opacity: active ? 1 : 0.4,
          child: CircleAvatar(
            backgroundColor: isTransfer
                ? AppTheme.macaron[4]
                : AppTheme.categoryColor(rule.categoryId),
            foregroundColor: AppTheme.onMacaron,
            child: Icon(icon, size: 20),
          ),
        ),
        title: Text(title),
        subtitle: Text([
          '每月 ${rule.dayOfMonth} 號',
          if (!isTransfer) accountName,
          if (rule.note.isNotEmpty) rule.note,
          if (!active) '已暫停',
        ].join(' · ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              switch (rule.type) {
                TransactionType.expense => '-${formatMoney(rule.amount, currency)}',
                TransactionType.income => '+${formatMoney(rule.amount, currency)}',
                TransactionType.transfer => formatMoney(rule.amount, currency),
              },
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: switch (rule.type) {
                  TransactionType.expense => AppTheme.expense,
                  TransactionType.income => AppTheme.income,
                  TransactionType.transfer => null,
                },
              ),
            ),
            Switch(
              value: active,
              onChanged: (v) {
                final db = ref.read(databaseProvider);
                final now = DateTime.now();
                (db.update(db.recurringRules)
                      ..where((r) => r.id.equals(rule.id)))
                    .write(RecurringRulesCompanion(
                  isActive: Value(v),
                  // 恢復時不補記暫停期間漏掉的，從今天之後才繼續產生
                  lastGenerated: v
                      ? Value(DateTime(now.year, now.month, now.day))
                      : const Value.absent(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
