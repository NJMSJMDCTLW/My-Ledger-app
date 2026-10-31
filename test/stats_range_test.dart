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
    test('Monthly: that one month, and the previous period is last month', () {
      final r = statsRangeFor(StatsPeriod.month, DateTime(2026, 10));
      expect(r.start, DateTime(2026, 10));
      expect(r.end, DateTime(2026, 11));
      expect(r.previousStart, DateTime(2026, 9));
      expect(r.previousEnd, DateTime(2026, 10));
    });

    test('Last six months: the selected month is the last one, correct across a year boundary', () {
      final r = statsRangeFor(StatsPeriod.sixMonths, DateTime(2026, 2));
      expect(r.start, DateTime(2025, 9));
      expect(r.end, DateTime(2026, 3));
      expect(r.months.length, 6);
      expect(r.previousStart, DateTime(2025, 3));
      expect(r.previousEnd, DateTime(2025, 9));
    });

    test('One year: the whole calendar year, and the previous period is last year', () {
      final r = statsRangeFor(StatsPeriod.year, DateTime(2026, 10));
      expect(r.start, DateTime(2026));
      expect(r.end, DateTime(2027));
      expect(r.months.length, 12);
      expect(r.previousStart, DateTime(2025));
      expect(r.previousEnd, DateTime(2026));
    });
  });

  test('The monthly average only divides by months that have started', () {
    final year = statsRangeFor(StatsPeriod.year, DateTime(2026, 10));
    expect(elapsedMonthCount(year, DateTime(2026, 10, 26)), 10);
    // Looking at a whole past year: all 12 months have passed
    final lastYear = statsRangeFor(StatsPeriod.year, DateTime(2025, 10));
    expect(elapsedMonthCount(lastYear, DateTime(2026, 10, 26)), 12);
  });

  test('monthlyTotals: sums each month separately, empty months are 0, transfers are not counted', () {
    final range = statsRangeFor(StatsPeriod.sixMonths, DateTime(2026, 10));
    final totals = monthlyTotals([
      tx(DateTime(2026, 10, 3), 1000),
      tx(DateTime(2026, 10, 9), 500),
      tx(DateTime(2026, 10, 9), 7000, type: TransactionType.income),
      tx(DateTime(2026, 8, 1), 300),
      tx(DateTime(2026, 8, 2), 9999, type: TransactionType.transfer),
      tx(DateTime(2026, 3, 31), 1), // outside the range
    ], range);

    expect(totals.map((t) => t.month.month), [5, 6, 7, 8, 9, 10]);
    expect(totals.map((t) => t.expense), [0, 0, 0, 300, 0, 1500]);
    expect(totals.map((t) => t.income), [0, 0, 0, 0, 0, 7000]);
  });

  test('computeRangeStats: includes the start date and excludes the end date', () {
    final all = [
      tx(DateTime(2026, 4, 1), 100), // the start day itself counts
      tx(DateTime(2026, 9, 30, 23, 59), 200), // before the end, counts
      tx(DateTime(2026, 10, 1), 400), // the end day itself, does not count
      tx(DateTime(2026, 3, 31), 800), // before the start, does not count
    ];
    final s = computeRangeStats(all, DateTime(2026, 4), DateTime(2026, 10));
    expect(s.expense, 300);
  });
}
