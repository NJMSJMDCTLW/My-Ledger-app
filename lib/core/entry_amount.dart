import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/hkd_converter.dart';

/// The amount a transaction is finally stored with: the amount in the account's currency, plus (when the currencies differ) the original value the user entered.
class EntryAmount {
  const EntryAmount({
    required this.amount,
    this.originalAmount,
    this.originalCurrency,
  });

  /// Amount in the account's currency (in cents); balances and statistics use this.
  final int amount;

  /// The original amount and currency the user entered; null when the entry currency equals the account's.
  final int? originalAmount;
  final String? originalCurrency;
}

/// Converts the amount the user entered (in [entryCurrency]) to an amount in the account's currency.
///
/// - Entry currency equals the account currency: used as is, no conversion.
/// - Otherwise: converted at the *current* rate. Returns null if a rate is missing.
/// - When editing an existing transaction and the entry currency, amount and account are all unchanged, the
///   previously converted amount is kept, so editing just a note does not shift the amount because the rate changed.
EntryAmount? resolveEntryAmount({
  required int enteredCents,
  required String entryCurrency,
  required int accountId,
  required HkdConverter converter,
  TransactionRecord? existing,
}) {
  final accountCurrency = converter.currencyOfAccount(accountId);
  if (entryCurrency == accountCurrency) {
    return EntryAmount(amount: enteredCents);
  }

  final unchanged = existing != null &&
      existing.accountId == accountId &&
      existing.originalCurrency == entryCurrency &&
      existing.originalAmount == enteredCents;
  if (unchanged) {
    return EntryAmount(
      amount: existing.amount,
      originalAmount: enteredCents,
      originalCurrency: entryCurrency,
    );
  }

  final converted = converter.convert(enteredCents, entryCurrency, accountCurrency);
  if (converted == null) return null;
  return EntryAmount(
    amount: converted,
    originalAmount: enteredCents,
    originalCurrency: entryCurrency,
  );
}
