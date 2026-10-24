import 'dart:math';

/// 某年某月的第 [day] 號。該月沒有這一天（例如 2 月 31 號）就用月底。
DateTime dayInMonth(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, min(day, lastDay));
}

/// 從 [today] 起（含今天）下一次出現「每月 [day] 號」的日期。
DateTime nextOccurrence(int day, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  final thisMonth = dayInMonth(t.year, t.month, day);
  return thisMonth.isBefore(t)
      ? dayInMonth(t.year, t.month + 1, day)
      : thisMonth;
}

/// 兩個日期相差幾天（用 UTC 算，避免日光節約時間造成誤差）。
int daysBetween(DateTime from, DateTime to) {
  return DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;
}

String daysLabel(int days) => switch (days) {
      0 => '今天',
      1 => '明天',
      _ => '$days 天後',
    };
