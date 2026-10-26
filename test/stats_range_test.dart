import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/stats_range.dart';

TransactionRecord tx(
  DateTime date,
  int amount, {
  TransactionType type = TransactionType.expense,
}) {
  return TransactionRecord(
    id: 0,
    date: date,
    amount: amount,
    type: type,
    accountId: 1,
    categoryId: 1,
    note: '',
    createdAt: date,
  );
}

void main() {
  group('statsRangeFor', () {
    test('每月：那一個月，上一期是上個月', () {
      final r = statsRangeFor(StatsPeriod.month, DateTime(2026, 10));
      expect(r.start, DateTime(2026, 10));
      expect(r.end, DateTime(2026, 11));
      expect(r.previousStart, DateTime(2026, 9));
      expect(r.previousEnd, DateTime(2026, 10));
    });

    test('近六個月：以選定月份為最後一個月，跨年也正確', () {
      final r = statsRangeFor(StatsPeriod.sixMonths, DateTime(2026, 2));
      expect(r.start, DateTime(2025, 9));
      expect(r.end, DateTime(2026, 3));
      expect(r.months.length, 6);
      expect(r.previousStart, DateTime(2025, 3));
      expect(r.previousEnd, DateTime(2025, 9));
    });

    test('一年：整個日曆年，上一期是去年', () {
      final r = statsRangeFor(StatsPeriod.year, DateTime(2026, 10));
      expect(r.start, DateTime(2026));
      expect(r.end, DateTime(2027));
      expect(r.months.length, 12);
      expect(r.previousStart, DateTime(2025));
      expect(r.previousEnd, DateTime(2026));
    });
  });

  test('月平均只除以已經開始的月份', () {
    final year = statsRangeFor(StatsPeriod.year, DateTime(2026, 10));
    expect(elapsedMonthCount(year, DateTime(2026, 10, 26)), 10);
    // 看去年整年：12 個月都已經過了
    final lastYear = statsRangeFor(StatsPeriod.year, DateTime(2025, 10));
    expect(elapsedMonthCount(lastYear, DateTime(2026, 10, 26)), 12);
  });

  test('monthlyTotals：每個月分開加總，沒有交易的月份是 0，轉帳不算', () {
    final range = statsRangeFor(StatsPeriod.sixMonths, DateTime(2026, 10));
    final totals = monthlyTotals([
      tx(DateTime(2026, 10, 3), 1000),
      tx(DateTime(2026, 10, 9), 500),
      tx(DateTime(2026, 10, 9), 7000, type: TransactionType.income),
      tx(DateTime(2026, 8, 1), 300),
      tx(DateTime(2026, 8, 2), 9999, type: TransactionType.transfer),
      tx(DateTime(2026, 3, 31), 1), // 範圍外
    ], range);

    expect(totals.map((t) => t.month.month), [5, 6, 7, 8, 9, 10]);
    expect(totals.map((t) => t.expense), [0, 0, 0, 300, 0, 1500]);
    expect(totals.map((t) => t.income), [0, 0, 0, 0, 0, 7000]);
  });

  test('computeRangeStats：包含起始日、不含結束日', () {
    final all = [
      tx(DateTime(2026, 4, 1), 100), // 起始當天，算
      tx(DateTime(2026, 9, 30, 23, 59), 200), // 結束前，算
      tx(DateTime(2026, 10, 1), 400), // 結束當天，不算
      tx(DateTime(2026, 3, 31), 800), // 起始前，不算
    ];
    final s = computeRangeStats(all, DateTime(2026, 4), DateTime(2026, 10));
    expect(s.expense, 300);
  });
}
