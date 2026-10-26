import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

/// 把各種貨幣的金額折算成港幣。
///
/// 用的是「目前」設定的匯率，不會記錄歷史匯率，所以改了匯率之後，
/// 過去外幣交易折合的港幣金額也會跟著變。
/// 還沒設定匯率的外幣，折算結果當作 0（用 [hasRate] 可以先檢查）。
class HkdConverter {
  const HkdConverter({
    this.rates = const {},
    this.accountCurrency = const {},
  });

  /// 貨幣代碼 -> 1 單位外幣等於多少港幣。
  final Map<String, double> rates;

  /// 帳戶 id -> 該帳戶的貨幣。
  final Map<int, String> accountCurrency;

  factory HkdConverter.from({
    required List<Account> accounts,
    required List<ExchangeRate> rates,
  }) {
    return HkdConverter(
      rates: {for (final r in rates) r.currency: r.rateToHkd},
      accountCurrency: {for (final a in accounts) a.id: a.currency},
    );
  }

  /// 1 單位 [currency] 等於多少港幣。港幣是 1，沒設定的外幣是 null。
  double? rateOf(String currency) =>
      currency == baseCurrency ? 1.0 : rates[currency];

  bool hasRate(String currency) => rateOf(currency) != null;

  String currencyOfAccount(int accountId) =>
      accountCurrency[accountId] ?? baseCurrency;

  /// [cents]（用 [currency] 計）折成港幣的「分」。沒有匯率回傳 0。
  int toHkd(int cents, String currency) {
    final rate = rateOf(currency);
    if (rate == null) return 0;
    return (cents * rate).round();
  }

  /// 把 [cents]（用 [from] 計）換成 [to] 貨幣。任一邊沒有匯率回傳 null。
  int? convert(int cents, String from, String to) {
    if (from == to) return cents;
    final fromRate = rateOf(from);
    final toRate = rateOf(to);
    if (fromRate == null || toRate == null || toRate == 0) return null;
    return (cents * fromRate / toRate).round();
  }

  /// 一筆交易的金額折成港幣（用它所屬帳戶的貨幣）。
  int amountOf(TransactionRecord t) =>
      toHkd(t.amount, currencyOfAccount(t.accountId));
}

/// 每個帳戶目前的餘額（單位：分，用該帳戶自己的貨幣），key 是帳戶 id。
///
/// 跨貨幣轉帳時，轉入帳戶收到的是 [TransactionRecord.toAmount]（沒有就跟轉出金額一樣）。
/// 不在 [accounts] 裡的帳戶（例如已封存）不會計入。
Map<int, int> computeBalances(
  List<Account> accounts,
  List<TransactionRecord> txs,
) {
  final balances = {for (final a in accounts) a.id: a.openingBalance};

  void add(int? id, int delta) {
    if (id != null && balances.containsKey(id)) {
      balances[id] = balances[id]! + delta;
    }
  }

  for (final t in txs) {
    switch (t.type) {
      case TransactionType.expense:
        add(t.accountId, -t.amount);
      case TransactionType.income:
        add(t.accountId, t.amount);
      case TransactionType.transfer:
        add(t.accountId, -t.amount);
        add(t.toAccountId, t.toAmount ?? t.amount);
    }
  }
  return balances;
}
