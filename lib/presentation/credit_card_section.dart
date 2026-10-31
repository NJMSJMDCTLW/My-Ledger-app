import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/billing_dates.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';

/// The credit card section: debt, available credit, and the next statement and due dates.
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
          child: Text(context.l10n.navCreditCards, style: Theme.of(context).textTheme.titleMedium),
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

    // Highlight in the warning color when there is debt and the due date is within 7 days
    final urgent = debt > 0 && dueDays != null && dueDays <= 7;
    final warnColor = theme.colorScheme.error;

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
                  context.l10n.creditDebt(formatMoney(debt, account.currency)),
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
                context.l10n.creditAvailable(
                  formatMoney(limit - debt, account.currency),
                  formatMoney(limit, account.currency),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              statement == null
                  ? context.l10n.statementDayNotSet
                  : context.l10n.nextStatement(
                      statement,
                      context.l10n.daysFromNow(daysBetween(today, statement)),
                    ),
            ),
            Text(
              due == null
                  ? context.l10n.dueDayNotSet
                  : [
                      context.l10n.nextPayment(
                        due,
                        context.l10n.daysFromNow(dueDays!),
                      ),
                      if (urgent) context.l10n.payReminder,
                    ].join(' '),
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
