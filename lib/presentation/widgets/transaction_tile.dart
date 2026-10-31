import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    required this.title,
    required this.icon,
    required this.accountName,
    required this.onTap,
    this.currency = baseCurrency,
    this.hkdAmount,
  });

  final TransactionRecord tx;
  final String title;
  final IconData icon;
  final String accountName;
  final VoidCallback onTap;

  /// The currency of the account this transaction belongs to; the amount is shown with this currency's symbol.
  final String currency;

  /// The HKD amount a foreign-currency transaction converts to (in cents). Not needed for HKD transactions.
  final int? hkdAmount;

  @override
  Widget build(BuildContext context) {
    final isTransfer = tx.type == TransactionType.transfer;

    final tile = ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isTransfer
            ? AppTheme.macaron[4]
            : AppTheme.categoryColor(tx.categoryId),
        foregroundColor: AppTheme.onMacaron,
        child: Icon(icon, size: 20),
      ),
      // If there is a note, append it after the category, e.g. "Food • Dinner"
      title: Text(
        tx.note.isEmpty ? title : '$title • ${tx.note}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // For a transaction entered in another currency, add the original amount, e.g. "Cash · original US$10.00"
      subtitle: isTransfer
          ? null
          : Text([
              accountName,
              if (tx.originalAmount != null && tx.originalCurrency != null)
                context.l10n.originalAmount(formatMoney(tx.originalAmount!, tx.originalCurrency!)),
            ].join(' · ')),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            switch (tx.type) {
              TransactionType.expense => '-${formatMoney(tx.amount, currency)}',
              TransactionType.income => '+${formatMoney(tx.amount, currency)}',
              TransactionType.transfer => formatMoney(tx.amount, currency),
            },
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: switch (tx.type) {
                TransactionType.expense => AppTheme.expense,
                TransactionType.income => AppTheme.income,
                TransactionType.transfer => null,
              },
            ),
          ),
          // for foreign currency, also show the HKD equivalent
          if (hkdAmount != null && currency != baseCurrency)
            Text(
              '≈ ${formatMoney(hkdAmount!, baseCurrency)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );

    // every transaction gets its own border
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: tile,
    );
  }
}
