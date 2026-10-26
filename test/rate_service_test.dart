import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/rate_service.dart';

/// 模擬匯率服務的回應：「1 港幣可以換多少外幣」。
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
    test('取倒數變成「1 外幣 = ? 港幣」，略過港幣與不合理的數字', () {
      final r = parseRatesResponse(_sample);
      expect(r['USD'], closeTo(7.8, 0.001)); // 1 / 0.128205
      expect(r['JPY'], closeTo(0.05, 1e-9));
      expect(r['TWD'], closeTo(0.25, 1e-9));
      expect(r.containsKey('HKD'), isFalse);
      expect(r.containsKey('XXX'), isFalse);
    });

    test('服務回傳失敗或格式不對會丟出例外', () {
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

    test('寫入支援的外幣，標成自動', () async {
      final n = await updateExchangeRates(db, fetch: () async => _sample);
      expect(n, 4); // USD、JPY、TWD、EUR（XXX 不是支援的貨幣）
      final rows = {
        for (final r in await db.select(db.exchangeRates).get()) r.currency: r,
      };
      expect(rows['USD']!.rateToHkd, closeTo(7.8, 0.001));
      expect(rows['USD']!.isManual, isFalse);
    });

    test('手動設定的匯率不會被蓋掉，自動的會被更新', () async {
      await setManualRate(db, 'USD', 8.0);
      await updateExchangeRates(db, fetch: () async => _sample);

      final rows = {
        for (final r in await db.select(db.exchangeRates).get()) r.currency: r,
      };
      expect(rows['USD']!.rateToHkd, 8.0);
      expect(rows['USD']!.isManual, isTrue);
      expect(rows['JPY']!.rateToHkd, closeTo(0.05, 1e-9));
    });

    test('改回自動之後，下次更新會換成最新的', () async {
      await setManualRate(db, 'USD', 8.0);
      await useAutomaticRate(db, 'USD');
      await updateExchangeRates(db, fetch: () async => _sample);

      final usd = (await db.select(db.exchangeRates).get())
          .firstWhere((r) => r.currency == 'USD');
      expect(usd.rateToHkd, closeTo(7.8, 0.001));
      expect(usd.isManual, isFalse);
    });

    test('抓失敗時資料庫不動', () async {
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

    test('沒有外幣帳戶就不用抓', () {
      expect(
        shouldAutoUpdate(rates: [], currenciesInUse: {'HKD'}, now: now),
        isFalse,
      );
    });

    test('用到的外幣還沒有匯率就要抓', () {
      expect(
        shouldAutoUpdate(rates: [], currenciesInUse: {'USD'}, now: now),
        isTrue,
      );
    });

    test('自動匯率超過 12 小時才抓；剛更新過不抓', () {
      final stale = rate('USD', at: now.subtract(const Duration(hours: 13)));
      final fresh = rate('USD', at: now.subtract(const Duration(hours: 2)));
      expect(shouldAutoUpdate(rates: [stale], currenciesInUse: {'USD'}, now: now), isTrue);
      expect(shouldAutoUpdate(rates: [fresh], currenciesInUse: {'USD'}, now: now), isFalse);
    });

    test('手動匯率再舊也不抓；沒在用的外幣不影響', () {
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
