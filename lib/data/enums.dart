import 'package:hello_ledger/l10n/app_localizations.dart';

enum AccountType { bank, cash, creditCard, eWallet }

enum CategoryType { expense, income }

enum TransactionType { expense, income, transfer }

extension AccountTypeLabel on AccountType {
  /// The translated name shown in the UI.
  String label(AppLocalizations l10n) => switch (this) {
        AccountType.bank => l10n.accountTypeBank,
        AccountType.cash => l10n.accountTypeCash,
        AccountType.creditCard => l10n.accountTypeCreditCard,
        AccountType.eWallet => l10n.accountTypeEWallet,
      };
}

extension TransactionTypeLabel on TransactionType {
  /// The translated name shown in the UI.
  String label(AppLocalizations l10n) => switch (this) {
        TransactionType.expense => l10n.expense,
        TransactionType.income => l10n.income,
        TransactionType.transfer => l10n.transfer,
      };
}
