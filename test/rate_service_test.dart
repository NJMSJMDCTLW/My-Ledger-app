import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/rate_service.dart';

/// Simulates the rate service response: how much of a currency 1 HKD buys.
const _sample = '''
{"result":"success","base_code":"HKD","rates":{
  "HKD":1,"USD":0.128205,"JPY":20.0,"TWD":4.0,"EUR":0.1,"XXX":0
}}
''';

ExchangeRate rate(String c, {bool manual = false, DateTime? at}) => ExchangeRate(
      currency: c,
      rateToHkd: 1,
      isManual: manual,
      updatedAt: at ?? DateTime(2026, 10, 1),
    );

void main() {
  group('parseRatesResponse', () {
    test('Inverts each value into 1 foreign unit = ? HKD, skipping HKD and unreasonable numbers', () {
      final r = parseRatesResponse(_sample);
      expect(r['USD'], closeTo(7.8, 0.001)); // 1 / 0.128205
      expect(r['JPY'], closeTo(0.05, 1e-9));
      expect(r['TWD'], closeTo(0.25, 1e-9));
      expect(r.containsKey('HKD'), isFalse);
      expect(r.containsKey('XXX'), isFalse);
    });

    test('A failed or malformed response throws an exception', () {
      expect(() => parseRatesResponse('{"result":"error"}'),
          throwsA(isA<RateFetchException>()));
      expect(() => parseRatesResponse('not json'),
          throwsA(isA<RateFetchException>()));
      expect(() => parseRatesResponse('{"result":"success"}'),
          throwsA(isA<RateFetchException>()));
    });
  });

  group('updateExchangeRates', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('Writes the supported foreign currencies, marked automatic', () async {
      final n = await updateExchangeRates(db, fetch: () async => _sample);
      expect(n, 4); // USD, JPY, TWD, EUR (XXX is not a supported currency)
      final rows = {
        for (final r in await db.select(db.exchangeRates).get()) r.currency: r,
      };
      expect(rows['USD']!.rateToHkd, closeTo(7.8, 0.001));
      expect(rows['USD']!.isManual, isFalse);
    });

    test('A manually set rate is not overwritten, while automatic ones are updated', () async {
      await setManualRate(db, 'USD', 8.0);
      await updateExchangeRates(db, fetch: () async => _sample);

      final rows = {
        for (final r in await db.select(db.exchangeRates).get()) r.currency: r,
      };
      expect(rows['USD']!.rateToHkd, 8.0);
      expect(rows['USD']!.isManual, isTrue);
      expect(rows['JPY']!.rateToHkd, closeTo(0.05, 1e-9));
    });

    test('After switching back to automatic, the next update replaces it with the latest', () async {
      await setManualRate(db, 'USD', 8.0);
      await useAutomaticRate(db, 'USD');
      await updateExchangeRates(db, fetch: () async => _sample);

      final usd = (await db.select(db.exchangeRates).get())
          .firstWhere((r) => r.currency == 'USD');
      expect(usd.rateToHkd, closeTo(7.8, 0.001));
      expect(usd.isManual, isFalse);
    });

    test('A failed fetch leaves the database untouched', () async {
      await setManualRate(db, 'USD', 8.0);
      await expectLater(
        updateExchangeRates(db, fetch: () async => throw const RateFetchException('無法連線')),
        throwsA(isA<RateFetchException>()),
      );
      final rows = await db.select(db.exchangeRates).get();
      expect(rows.single.rateToHkd, 8.0);
    });
  });

  group('shouldAutoUpdate', () {
    final now = DateTime(2026, 10, 27, 12);

    test('No fetch is needed without foreign-currency accounts', () {
      expect(
        shouldAutoUpdate(rates: [], currenciesInUse: {'HKD'}, now: now),
        isFalse,
      );
    });

    test('Fetch when a foreign currency in use has no rate yet', () {
      expect(
        shouldAutoUpdate(rates: [], currenciesInUse: {'USD'}, now: now),
        isTrue,
      );
    });

    test('Automatic rates are fetched only after 12 hours; not right after an update', () {
      final stale = rate('USD', at: now.subtract(const Duration(hours: 13)));
      final fresh = rate('USD', at: now.subtract(const Duration(hours: 2)));
      expect(shouldAutoUpdate(rates: [stale], currenciesInUse: {'USD'}, now: now), isTrue);
      expect(shouldAutoUpdate(rates: [fresh], currenciesInUse: {'USD'}, now: now), isFalse);
    });

    test('A manual rate is never fetched however old it is; currencies not in use do not matter', () {
      final manual = rate('USD', manual: true, at: DateTime(2020));
      final staleUnused = rate('JPY', at: DateTime(2020));
      expect(
        shouldAutoUpdate(
            rates: [manual, staleUnused], currenciesInUse: {'USD'}, now: now),
        isFalse,
      );
    });
  });
}
