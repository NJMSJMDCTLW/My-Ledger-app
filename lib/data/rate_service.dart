import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/data/app_database.dart';

/// 匯率資料來源：ExchangeRate-API 的免費公開端點（不需要金鑰，每天更新一次）。
/// 使用條款要求註明來源，所以匯率分頁會顯示 [rateSourceName]。
const rateSourceUrl = 'https://open.er-api.com/v6/latest/$baseCurrency';
const rateSourceName = 'ExchangeRate-API (exchangerate-api.com)';

/// 抓匯率失敗（沒網路、伺服器錯誤、格式不對）。[message] 可以直接顯示給使用者。
class RateFetchException implements Exception {
  const RateFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 取得匯率原始 JSON 的函式。測試時可以換成假的，不用真的連網路。
typedef RateFetcher = Future<String> Function();

/// 真的連到網路抓匯率。
Future<String> fetchRatesFromNetwork() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client
        .getUrl(Uri.parse(rateSourceUrl))
        .timeout(const Duration(seconds: 15));
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw RateFetchException('匯率服務暫時無法使用（${response.statusCode}）');
    }
    return await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 15));
  } on RateFetchException {
    rethrow;
  } on TimeoutException {
    throw const RateFetchException('連線逾時，請確認網路後再試');
  } on SocketException {
    throw const RateFetchException('無法連線，請確認網路');
  } on HandshakeException {
    throw const RateFetchException('無法建立安全連線，請確認網路');
  } finally {
    client.close();
  }
}

/// 解析匯率 JSON，回傳「貨幣代碼 -> 1 單位外幣等於多少港幣」。
///
/// 服務回傳的是「1 港幣可以換多少外幣」，所以要取倒數。
/// 數字不合理（缺少、0、負數）的貨幣會被略過。
Map<String, double> parseRatesResponse(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw const RateFetchException('匯率資料格式不正確');
  }
  if (decoded is! Map || decoded['result'] != 'success') {
    throw const RateFetchException('匯率服務回傳錯誤');
  }
  final rates = decoded['rates'];
  if (rates is! Map) throw const RateFetchException('匯率資料格式不正確');

  final result = <String, double>{};
  for (final entry in rates.entries) {
    final code = entry.key;
    final perHkd = entry.value;
    if (code is! String || code == baseCurrency) continue;
    if (perHkd is num && perHkd > 0) result[code] = 1 / perHkd.toDouble();
  }
  return result;
}

/// 更新所有支援的外幣匯率，回傳更新了幾種。
///
/// 使用者手動設定的匯率（isManual）不會被覆蓋。
/// 沒抓到的貨幣維持原本的值。抓失敗會丟出 [RateFetchException]，資料庫不動。
Future<int> updateExchangeRates(
  AppDatabase db, {
  RateFetcher? fetch,
  DateTime? now,
}) async {
  final fetched = parseRatesResponse(await (fetch ?? fetchRatesFromNetwork)());
  final time = now ?? DateTime.now();

  final existing = {
    for (final r in await db.select(db.exchangeRates).get()) r.currency: r,
  };

  var updated = 0;
  await db.transaction(() async {
    for (final c in supportedCurrencies) {
      if (c.code == baseCurrency) continue;
      final rate = fetched[c.code];
      if (rate == null) continue;
      if (existing[c.code]?.isManual ?? false) continue;

      await db.into(db.exchangeRates).insertOnConflictUpdate(
            ExchangeRatesCompanion.insert(
              currency: c.code,
              rateToHkd: rate,
              isManual: const Value(false),
              updatedAt: Value(time),
            ),
          );
      updated++;
    }
  });
  return updated;
}

/// 使用者自己填的匯率：標成手動，之後自動更新不會蓋掉。
Future<void> setManualRate(AppDatabase db, String currency, double rate) {
  return db.into(db.exchangeRates).insertOnConflictUpdate(
        ExchangeRatesCompanion.insert(
          currency: currency,
          rateToHkd: rate,
          isManual: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}

/// 把某個匯率改回自動更新（下次更新時會換成最新的）。
Future<void> useAutomaticRate(AppDatabase db, String currency) {
  return (db.update(db.exchangeRates)..where((r) => r.currency.equals(currency)))
      .write(const ExchangeRatesCompanion(isManual: Value(false)));
}

/// App 啟動時要不要自動去抓匯率。
///
/// 只有用得到外幣的時候才抓（沒有外幣帳戶就不連網路）：
/// 有外幣還沒有匯率，或自動更新的匯率已經超過 [maxAge] 沒更新。
/// 手動設定的匯率不算。
bool shouldAutoUpdate({
  required List<ExchangeRate> rates,
  required Set<String> currenciesInUse,
  required DateTime now,
  Duration maxAge = const Duration(hours: 12),
}) {
  final byCode = {for (final r in rates) r.currency: r};
  for (final code in currenciesInUse) {
    if (code == baseCurrency) continue;
    final rate = byCode[code];
    if (rate == null) return true;
    if (rate.isManual) continue;
    if (now.difference(rate.updatedAt) > maxAge) return true;
  }
  return false;
}
