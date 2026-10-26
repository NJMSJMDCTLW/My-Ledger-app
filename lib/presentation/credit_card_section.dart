import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/billing_dates.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:intl/intl.dart';

/// 首頁的信用卡區塊：欠款、可用額度、下次結帳日與繳款日。
class CreditCardSection extends StatelessWidget {
  const CreditCardSection({
    super.key,
    required this.cards,
    required this.balances,
  });

  final List<Account> cards;
  final Map<int, int> balances;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 4),
          child: Text('信用卡', style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final c in cards)
          _CardTile(account: c, balance: balances[c.id] ?? 0),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.account, required this.balance});

  final Account account;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final debt = balance < 0 ? -balance : 0;
    final limit = account.creditLimit;

    final statement = account.statementDay == null
        ? null
        : nextOccurrence(account.statementDay!, today);
    final due = account.dueDay == null
        ? null
        : nextOccurrence(account.dueDay!, today);
    final dueDays = due == null ? null : daysBetween(today, due);

    // 有欠款、且 7 天內要繳款，就標成警示色
    final urgent = debt > 0 && dueDays != null && dueDays <= 7;
    final warnColor = theme.colorScheme.error;
    final fmt = DateFormat('M/d');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  account.last4 == null
                      ? account.name
                      : '${account.name} (${account.last4})',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '欠款 ${formatMoney(debt, account.currency)}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            if (limit != null && limit > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (debt / limit).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: AppTheme.macaron[0],
                backgroundColor: AppTheme.macaron[0].withValues(alpha: 0.25),
              ),
              const SizedBox(height: 4),
              Text(
                '可用額度 ${formatMoney(limit - debt, account.currency)} / ${formatMoney(limit, account.currency)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              statement == null
                  ? '結帳日：未設定'
                  : '下次結帳：${fmt.format(statement)}'
                      '（${daysLabel(daysBetween(today, statement))}）',
            ),
            Text(
              due == null
                  ? '繳款日：未設定'
                  : '下次繳款：${fmt.format(due)}（${daysLabel(dueDays!)}）'
                      '${urgent ? ' ⚠ 記得繳款' : ''}',
              style: urgent
                  ? TextStyle(color: warnColor, fontWeight: FontWeight.bold)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
