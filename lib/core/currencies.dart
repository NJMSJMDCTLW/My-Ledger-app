/// App 支援的貨幣。資料庫裡存的是代碼（例如 'USD'）。
class CurrencyInfo {
  const CurrencyInfo(this.code, this.name, this.symbol);

  final String code;
  final String name;
  final String symbol;
}

/// 本位幣：所有統計與總資產最後都折算成港幣。
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

/// 找不到的代碼（理論上不會發生）就用代碼本身當名稱和符號。
CurrencyInfo currencyInfo(String code) {
  for (final c in supportedCurrencies) {
    if (c.code == code) return c;
  }
  return CurrencyInfo(code, code, code);
}
