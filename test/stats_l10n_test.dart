import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/data/stats_range.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:hello_ledger/presentation/tabs/stats_tab.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: StatsTab()),
    );
  }
}

const hkd = 'HKD';

Account get account => const Account(
      id: 1,
      name: 'Main',
      type: AccountType.bank,
      currency: hkd,
      openingBalance: 0,
      isArchived: false,
    );

const categories = [
  Category(id: 1, name: 'Food', type: CategoryType.expense),
  Category(id: 2, name: 'Salary', type: CategoryType.income),
  Category(id: 3, name: 'Travel', type: CategoryType.expense),
];

TransactionRecord tx(DateTime date, int amount, TransactionType type, int category) {
  return TransactionRecord(
    id: 0,
    date: date,
    amount: amount,
    type: type,
    accountId: 1,
    categoryId: category,
    note: '',
    createdAt: date,
  );
}

/// This month: Food HK$200, Salary HK$500.  Last month: Food HK$100, Travel HK$50.
List<TransactionRecord> transactions() {
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month, 1);
  final lastMonth = DateTime(now.year, now.month - 1, 1);
  return [
    tx(thisMonth, 20000, TransactionType.expense, 1),
    tx(thisMonth, 50000, TransactionType.income, 2),
    tx(lastMonth, 10000, TransactionType.expense, 1),
    tx(lastMonth, 5000, TransactionType.expense, 3),
  ];
}

Future<void> pumpStats(WidgetTester tester, {required String language}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(
    {AppLanguageNotifier.storageKey: language},
  );
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allAccountsProvider.overrideWith((ref) => Stream.value([account])),
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        transactionsProvider
            .overrideWith((ref) => Stream.value(transactions())),
        exchangeRatesProvider
            .overrideWith((ref) => Stream.value(const <ExchangeRate>[])),
      ],
      child: const _App(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('zh_TW');
  });

  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month);
  final lastMonth = DateTime(now.year, now.month - 1);

  group('English', () {
    testWidgets('Monthly view: title, summary, comparison and categories',
        (tester) async {
      await pumpStats(tester, language: 'english');

      // The range switch and the month title
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Last 6 months'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text(DateFormat.yMMMM('en').format(thisMonth)), findsOneWidget);
      expect(find.byTooltip('Go back'), findsOneWidget);
      expect(find.byTooltip('Go forward'), findsOneWidget);

      // Comparison with last month (the previous month's name in parentheses)
      expect(
        find.text('Compared with last month (${DateFormat.MMMM('en').format(lastMonth)})'),
        findsOneWidget,
      );
      // Expense went from 150 to 200: +50, +33%
      expect(find.text('▲ 50.00 (+33%)'), findsOneWidget);
      expect(find.text('last month 150.00'), findsOneWidget);

      // Categories: Food doubled, Travel disappeared
      expect(find.text('Expenses by category'), findsOneWidget);
      expect(find.text('▲ 100.00 (+100%)'), findsOneWidget); // Food
      expect(find.text('▼ 50.00 (-100%)'), findsOneWidget); // Travel
      expect(find.text('Total expense'), findsOneWidget);
    });

    testWidgets('Last 6 months adds the averages and the bar chart', (tester) async {
      await pumpStats(tester, language: 'english');
      expect(find.text('Average monthly expense'), findsNothing);

      await tester.tap(find.text('Last 6 months'));
      await tester.pumpAndSettle();

      expect(find.text('Average monthly expense'), findsOneWidget);
      expect(find.text('Average monthly income'), findsOneWidget);
      expect(find.text('Monthly income and expenses'), findsOneWidget);
      expect(find.textContaining('Compared with the previous six months ('),
          findsOneWidget);
    });

    testWidgets('Year view shows the year and compares with last year',
        (tester) async {
      await pumpStats(tester, language: 'english');

      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      expect(find.text('${now.year}'), findsOneWidget);
      expect(find.text('Compared with last year (${now.year - 1})'), findsOneWidget);
      expect(find.text('Monthly income and expenses'), findsOneWidget);
    });

    testWidgets('A period with no records in the previous period says so',
        (tester) async {
      await pumpStats(tester, language: 'english');

      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      // Nothing was recorded last year
      expect(
        find.text('There are no records for last year, so there is nothing to compare.'),
        findsOneWidget,
      );
    });
  });

  group('Traditional Chinese', () {
    testWidgets('Monthly view', (tester) async {
      await pumpStats(tester, language: 'traditionalChinese');

      expect(find.text('每月'), findsOneWidget);
      expect(find.text('近六個月'), findsOneWidget);
      expect(find.text('一年'), findsOneWidget);
      expect(find.text(DateFormat.yMMMM('zh_TW').format(thisMonth)), findsOneWidget);
      expect(find.byTooltip('往前'), findsOneWidget);
      expect(find.byTooltip('往後'), findsOneWidget);

      expect(
        find.text('與上個月比較（${DateFormat.MMMM('zh_TW').format(lastMonth)}）'),
        findsOneWidget,
      );
      expect(find.text('▲ 50.00 (+33%)'), findsOneWidget);
      expect(find.text('上月 150.00'), findsOneWidget);
      expect(find.text('支出類別'), findsOneWidget);
      expect(find.text('總支出'), findsOneWidget);
      // English wording must be gone
      expect(find.text('Monthly'), findsNothing);
    });

    testWidgets('Six months and year views', (tester) async {
      await pumpStats(tester, language: 'traditionalChinese');

      await tester.tap(find.text('近六個月'));
      await tester.pumpAndSettle();
      expect(find.text('平均每月支出'), findsOneWidget);
      expect(find.text('平均每月收入'), findsOneWidget);
      expect(find.text('每月收支'), findsOneWidget);
      expect(find.textContaining('與前六個月比較（'), findsOneWidget);

      await tester.tap(find.text('一年'));
      await tester.pumpAndSettle();
      expect(find.text('${now.year}年'), findsOneWidget);
      expect(find.text('與去年比較（${now.year - 1}年）'), findsOneWidget);
      expect(find.text('去年沒有紀錄，無法比較'), findsOneWidget);
    });
  });

  test('Every period has a translated label and comparison name', () {
    final en = AppLocalizationsLookup.en;
    final zh = AppLocalizationsLookup.zh;
    for (final period in StatsPeriod.values) {
      expect(period.label(en), isNotEmpty);
      expect(period.label(zh), isNot(period.label(en)));
      expect(period.previousName(zh), isNot(period.previousName(en)));
    }
  });
}

/// Direct access to the two translations without building a widget tree.
class AppLocalizationsLookup {
  static final en = lookupAppLocalizations(const Locale('en'));
  static final zh = lookupAppLocalizations(const Locale('zh'));
}
