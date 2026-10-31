/// The currencies the app supports. The database stores the code (e.g. 'USD').
class CurrencyInfo {
  const CurrencyInfo(this.code, this.name, this.symbol);

  final String code;
  final String name;
  final String symbol;
}

/// Base currency: all statistics and the total balance are ultimately converted to Hong Kong dollars.
const baseCurrency = 'HKD';

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo('HKD', '港幣', 'HK\$'),
  CurrencyInfo('USD', '美元', 'US\$'),
  CurrencyInfo('CNY', '人民幣', 'CN¥'),
  CurrencyInfo('TWD', '新台幣', 'NT\$'),
  CurrencyInfo('JPY', '日圓', 'JP¥'),
  CurrencyInfo('KRW', '韓圜', '₩'),
  CurrencyInfo('EUR', '歐元', '€'),
  CurrencyInfo('GBP', '英鎊', '£'),
  CurrencyInfo('SGD', '新加坡幣', 'S\$'),
  CurrencyInfo('AUD', '澳幣', 'A\$'),
  CurrencyInfo('CAD', '加幣', 'C\$'),
  CurrencyInfo('THB', '泰銖', '฿'),
];

/// An unknown code (should not happen) falls back to using the code itself as name and symbol.
CurrencyInfo currencyInfo(String code) {
  for (final c in supportedCurrencies) {
    if (c.code == code) return c;
  }
  return CurrencyInfo(code, code, code);
}
