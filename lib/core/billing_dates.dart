import 'dart:math';

/// The [day]th of the given month. If the month has no such day (e.g. Feb 31), use the last day of the month.
DateTime dayInMonth(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, min(day, lastDay));
}

/// The next date, starting from [today] (inclusive), that falls on day [day] of a month.
DateTime nextOccurrence(int day, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  final thisMonth = dayInMonth(t.year, t.month, day);
  return thisMonth.isBefore(t)
      ? dayInMonth(t.year, t.month + 1, day)
      : thisMonth;
}

/// Number of days between two dates (computed in UTC to avoid daylight-saving errors).
int daysBetween(DateTime from, DateTime to) {
  return DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;
}

