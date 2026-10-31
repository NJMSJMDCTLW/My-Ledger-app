/// The currencies the app supports. The database stores the code (e.g. 'USD').
/// The display name is translated, see `currencyName` in currency_names.dart.
class CurrencyInfo {
  const CurrencyInfo(this.code, this.symbol);

  final String code;
  final String symbol;
}

/// Base currency: all statistics and the total balance are ultimately converted to Hong Kong dollars.
const baseCurrency = 'HKD';

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo('HKD', 'HK\$'),
  CurrencyInfo('USD', 'US\$'),
  CurrencyInfo('CNY', 'CN¥'),
  CurrencyInfo('TWD', 'NT\$'),
  CurrencyInfo('JPY', 'JP¥'),
  CurrencyInfo('KRW', '₩'),
  CurrencyInfo('EUR', '€'),
  CurrencyInfo('GBP', '£'),
  CurrencyInfo('SGD', 'S\$'),
  CurrencyInfo('AUD', 'A\$'),
  CurrencyInfo('CAD', 'C\$'),
  CurrencyInfo('THB', '฿'),
];

/// An unknown code (should not happen) falls back to using the code itself as the symbol.
CurrencyInfo currencyInfo(String code) {
  for (final c in supportedCurrencies) {
    if (c.code == code) return c;
  }
  return CurrencyInfo(code, code);
}
