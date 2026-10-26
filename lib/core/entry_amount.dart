import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/hkd_converter.dart';

/// 一筆交易最後要存的金額：帳戶貨幣的金額，以及（貨幣不同時）使用者輸入的原始值。
class EntryAmount {
  const EntryAmount({
    required this.amount,
    this.originalAmount,
    this.originalCurrency,
  });

  /// 帳戶貨幣的金額（單位：分），餘額與統計都用這個。
  final int amount;

  /// 使用者輸入的原始金額與貨幣；輸入的貨幣和帳戶相同時是 null。
  final int? originalAmount;
  final String? originalCurrency;
}

/// 把使用者輸入的金額（用 [entryCurrency] 計）換成帳戶貨幣的金額。
///
/// - 輸入貨幣和帳戶貨幣一樣：直接用，不用換算。
/// - 不一樣：依「目前」匯率換算。有匯率沒設定就回傳 null。
/// - 編輯舊交易時，如果輸入的貨幣、金額、帳戶都沒變，沿用原本換算好的金額，
///   這樣只是改個備註不會因為匯率變了而讓金額跟著跑掉。
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
