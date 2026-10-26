import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
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
  });

  final TransactionRecord tx;
  final String title;
  final IconData icon;
  final String accountName;
  final VoidCallback onTap;

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
      // 有備註就接在類別後面，例如「餐飲 • 晚餐」
      title: Text(
        tx.note.isEmpty ? title : '$title • ${tx.note}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: isTransfer ? null : Text(accountName),
      trailing: Text(
        switch (tx.type) {
          TransactionType.expense => '-${formatCents(tx.amount)}',
          TransactionType.income => '+${formatCents(tx.amount)}',
          TransactionType.transfer => formatCents(tx.amount),
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
    );

    // 每一筆都有自己的邊框
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
