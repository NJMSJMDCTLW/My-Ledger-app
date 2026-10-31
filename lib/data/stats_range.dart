import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/hkd_converter.dart';

/// The time ranges the statistics tab can show.
enum StatsPeriod { month, sixMonths, year }

extension StatsPeriodLabel on StatsPeriod {
  String get label => switch (this) {
        StatsPeriod.month => '每月',
        StatsPeriod.sixMonths => '近六個月',
        StatsPeriod.year => '一年',
      };

  /// Name of the comparison target, used in text like "last month", "the previous six months", "last year".
  String get previousName => switch (this) {
        StatsPeriod.month => '上月',
        StatsPeriod.sixMonths => '前六個月',
        StatsPeriod.year => '去年',
      };

  /// How many months the left/right arrows move at a time.
  int get stepMonths => switch (this) {
        StatsPeriod.month => 1,
        StatsPeriod.sixMonths => 6,
        StatsPeriod.year => 12,
      };
}

/// A statistics range, plus the "previous period" range used for comparison. Dates are month starts; [end] is exclusive.
class StatsRange {
  const StatsRange({
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
  });

  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime previousEnd;

  /// Every month in the range (as month starts).
  List<DateTime> get months => _monthsBetween(start, end);
}

/// Computes the range relative to [anchor] (the start of some month):
/// - Monthly: just that one month.
/// - Last six months: [anchor] is the last month, going back six months in total.
/// - One year: the whole calendar year that [anchor] falls in (January to December).
StatsRange statsRangeFor(StatsPeriod period, DateTime anchor) {
  final a = DateTime(anchor.year, anchor.month);
  switch (period) {
    case StatsPeriod.month:
      return StatsRange(
        start: a,
        end: DateTime(a.year, a.month + 1),
        previousStart: DateTime(a.year, a.month - 1),
        previousEnd: a,
      );
    case StatsPeriod.sixMonths:
      final start = DateTime(a.year, a.month - 5);
      return StatsRange(
        start: start,
        end: DateTime(a.year, a.month + 1),
        previousStart: DateTime(a.year, a.month - 11),
        previousEnd: start,
      );
    case StatsPeriod.year:
      final start = DateTime(a.year);
      return StatsRange(
        start: start,
        end: DateTime(a.year + 1),
        previousStart: DateTime(a.year - 1),
        previousEnd: start,
      );
  }
}

List<DateTime> _monthsBetween(DateTime start, DateTime end) {
  final result = <DateTime>[];
  for (var m = start; m.isBefore(end); m = DateTime(m.year, m.month + 1)) {
    result.add(m);
  }
  return result;
}

/// How many months to divide by for a "monthly average": months in the range that have started (excluding future months), at least 1.
int elapsedMonthCount(StatsRange range, DateTime now) {
  final thisMonth = DateTime(now.year, now.month);
  final count = range.months.where((m) => !m.isAfter(thisMonth)).length;
  return count < 1 ? 1 : count;
}

/// Income and expense for one month (in cents), used to draw the bar chart. Transfers are not counted.
class MonthTotals {
  const MonthTotals(this.month, this.income, this.expense);

  final DateTime month;
  final int income;
  final int expense;
}

/// Sums income and expense separately for each month in [range]; a month with no transactions is 0.
/// With a [converter], each amount is converted to HKD before summing.
List<MonthTotals> monthlyTotals(
  List<TransactionRecord> all,
  StatsRange range, {
  HkdConverter? converter,
}) {
  return [
    for (final m in range.months)
      () {
        var income = 0;
        var expense = 0;
        for (final t in all) {
          if (t.date.year != m.year || t.date.month != m.month) continue;
          final amount = converter?.amountOf(t) ?? t.amount;
          if (t.type == TransactionType.income) income += amount;
          if (t.type == TransactionType.expense) expense += amount;
        }
        return MonthTotals(m, income, expense);
      }(),
  ];
}
