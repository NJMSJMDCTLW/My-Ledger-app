import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

/// Converts amounts in various currencies to Hong Kong dollars.
///
/// It uses the *current* rates and keeps no rate history, so changing a rate also changes the HKD value
/// of past foreign-currency transactions.
/// A foreign currency with no rate set converts to 0 (check first with [hasRate]).
class HkdConverter {
  const HkdConverter({
    this.rates = const {},
    this.accountCurrency = const {},
  });

  /// Currency code -> how many HKD one unit of that currency is worth.
  final Map<String, double> rates;

  /// Account id -> that account's currency.
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

  /// How many HKD one unit of [currency] is worth. HKD is 1; a foreign currency with no rate is null.
  double? rateOf(String currency) =>
      currency == baseCurrency ? 1.0 : rates[currency];

  bool hasRate(String currency) => rateOf(currency) != null;

  String currencyOfAccount(int accountId) =>
      accountCurrency[accountId] ?? baseCurrency;

  /// [cents] (in [currency]) converted to HKD cents. Returns 0 if there is no rate.
  int toHkd(int cents, String currency) {
    final rate = rateOf(currency);
    if (rate == null) return 0;
    return (cents * rate).round();
  }

  /// Converts [cents] (in [from]) to the [to] currency. Returns null if either side has no rate.
  int? convert(int cents, String from, String to) {
    if (from == to) return cents;
    final fromRate = rateOf(from);
    final toRate = rateOf(to);
    if (fromRate == null || toRate == null || toRate == 0) return null;
    return (cents * fromRate / toRate).round();
  }

  /// A transaction's amount converted to HKD (using its account's currency).
  int amountOf(TransactionRecord t) =>
      toHkd(t.amount, currencyOfAccount(t.accountId));
}

/// Each account's current balance (in cents, in that account's own currency), keyed by account id.
///
/// For a cross-currency transfer, the destination account receives [TransactionRecord.toAmount] (or the same as the amount sent if null).
/// Accounts not in [accounts] (e.g. archived ones) are not counted.
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
