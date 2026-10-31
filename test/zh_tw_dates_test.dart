import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('zh');
    await initializeDateFormatting('zh_TW');
  });

  final saturday = DateTime(2026, 10, 31);

  // The app selects the locale zh_TW for Traditional Chinese (see app_language.dart). The dates
  // must use Taiwan's patterns and characters, not the plain zh (Simplified-style) ones.
  group('Traditional Chinese dates use Taiwan conventions', () {
    final tw = lookupAppLocalizations(const Locale('zh', 'TW'));

    test('The locale zh_TW resolves to the Taiwan translation', () {
      expect(tw.localeName, 'zh_TW');
    });

    test('Weekdays use 週, months are written as numbers plus 月', () {
      expect(tw.dayHeader(saturday), contains('週'));
      expect(tw.dayHeader(saturday), isNot(contains('周')));
      expect(tw.formatMonthName(DateTime(2026, 9)), '9月');
      expect(tw.monthTitle(DateTime(2026, 10)), '2026年10月');
      expect(tw.formatDate(DateTime(2026, 10, 5)), '2026/10/5');
      expect(tw.formatYear(DateTime(2026)), '2026年');
      expect(tw.formatMonthShort(DateTime(2026, 10)), '10月');
    });

    test('Every non-date text still comes from the Chinese translation', () {
      expect(tw.totalBalance, '總資產');
      expect(tw.fabAddTransaction, '記一筆');
      expect(tw.comparisonSame('上月'), '與上月持平');
    });

    test('Next statement and payment dates are formatted', () {
      expect(tw.nextStatement(DateTime(2026, 11, 5), '5 天後'), '下次結帳：11/5（5 天後）');
      expect(tw.nextPayment(DateTime(2026, 11, 5), '明天'), '下次繳款：11/5（明天）');
    });
  });

  test('English dates use English conventions', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.formatMonthName(DateTime(2026, 9)), 'September');
    expect(en.monthTitle(DateTime(2026, 10)), 'October 2026');
    expect(en.dayHeader(saturday), 'Sat, Oct 31');
  });
}
