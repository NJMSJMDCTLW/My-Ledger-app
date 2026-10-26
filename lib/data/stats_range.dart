import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/hkd_converter.dart';

/// 統計分頁可以看的時間範圍。
enum StatsPeriod { month, sixMonths, year }

extension StatsPeriodLabel on StatsPeriod {
  String get label => switch (this) {
        StatsPeriod.month => '每月',
        StatsPeriod.sixMonths => '近六個月',
        StatsPeriod.year => '一年',
      };

  /// 比較對象的名稱，用在「上月」「前六個月」「去年」這類文字。
  String get previousName => switch (this) {
        StatsPeriod.month => '上月',
        StatsPeriod.sixMonths => '前六個月',
        StatsPeriod.year => '去年',
      };

  /// 按左右箭頭時，一次移動幾個月。
  int get stepMonths => switch (this) {
        StatsPeriod.month => 1,
        StatsPeriod.sixMonths => 6,
        StatsPeriod.year => 12,
      };
}

/// 一個統計範圍，以及用來比較的「上一期」範圍。日期都是月初，[end] 不含。
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

  /// 範圍內的每個月（月初）。
  List<DateTime> get months => _monthsBetween(start, end);
}

/// 以 [anchor]（某月月初）為基準算出範圍：
/// - 每月：就是那一個月。
/// - 近六個月：以 [anchor] 為最後一個月，往前共六個月。
/// - 一年：[anchor] 所在的那一整個日曆年（1 月到 12 月）。
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

/// 計算「月平均」要除以幾個月：範圍內已經開始的月份（不含還沒到的未來月份），至少 1。
int elapsedMonthCount(StatsRange range, DateTime now) {
  final thisMonth = DateTime(now.year, now.month);
  final count = range.months.where((m) => !m.isAfter(thisMonth)).length;
  return count < 1 ? 1 : count;
}

/// 某個月的收入與支出（單位：分），畫長條圖用。轉帳不算。
class MonthTotals {
  const MonthTotals(this.month, this.income, this.expense);

  final DateTime month;
  final int income;
  final int expense;
}

/// 把 [range] 內每個月的收入、支出分別加總，沒有交易的月份是 0。
/// 給了 [converter] 就把每筆金額折成港幣再加總。
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
