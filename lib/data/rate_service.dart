import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/data/app_database.dart';

/// Exchange-rate source: the free open endpoint of ExchangeRate-API (no key needed, updated once a day).
/// Its terms require attribution, so the rates tab shows [rateSourceName].
const rateSourceUrl = 'https://open.er-api.com/v6/latest/$baseCurrency';
const rateSourceName = 'ExchangeRate-API (exchangerate-api.com)';

/// Fetching rates failed (offline, server error, bad format). [message] can be shown to the user directly.
class RateFetchException implements Exception {
  const RateFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A function that returns the raw rates JSON. Tests can swap in a fake one so no real network is used.
typedef RateFetcher = Future<String> Function();

/// Actually fetches the rates over the network.
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

/// Parses the rates JSON and returns "currency code -> how many HKD one unit of it is worth".
///
/// The service returns "how much of a currency 1 HKD buys", so each value is inverted.
/// Currencies with an unreasonable number (missing, 0, or negative) are skipped.
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

/// Updates the rates of all supported foreign currencies and returns how many were updated.
///
/// Rates the user set manually (isManual) are never overwritten.
/// Currencies that were not fetched keep their previous value. A failed fetch throws [RateFetchException] and leaves the database untouched.
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

/// A rate the user entered: marked manual, so automatic updates will not overwrite it.
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

/// Switches a rate back to automatic updates (it is replaced with the latest one on the next update).
Future<void> useAutomaticRate(AppDatabase db, String currency) {
  return (db.update(db.exchangeRates)..where((r) => r.currency.equals(currency)))
      .write(const ExchangeRatesCompanion(isManual: Value(false)));
}

/// Whether to fetch the rates automatically when the app starts.
///
/// Only fetch when a foreign currency is actually in use (no foreign-currency accounts means no network use):
/// a foreign currency has no rate yet, or its automatic rate has not been updated for more than [maxAge].
/// Manually set rates do not count.
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
