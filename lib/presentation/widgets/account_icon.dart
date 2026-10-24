import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/data/enums.dart';

class AccountIcon extends StatelessWidget {
  const AccountIcon(this.type, {super.key});

  final AccountType type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      AccountType.bank => Icons.account_balance,
      AccountType.cash => Icons.payments_outlined,
      AccountType.creditCard => Icons.credit_card,
      AccountType.eWallet => Icons.phone_android,
    };
    return CircleAvatar(
      backgroundColor:
          AppTheme.macaron[type.index * 2 % AppTheme.macaron.length],
      foregroundColor: AppTheme.onMacaron,
      child: Icon(icon, size: 20),
    );
  }
}
