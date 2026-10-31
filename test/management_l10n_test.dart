import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/core/notification_service.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/rate_service.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:hello_ledger/presentation/category_form_page.dart';
import 'package:hello_ledger/presentation/recurring_form_page.dart';
import 'package:hello_ledger/presentation/tabs/categories_tab.dart';
import 'package:hello_ledger/presentation/tabs/rates_tab.dart';
import 'package:hello_ledger/presentation/tabs/recurring_tab.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _App extends ConsumerWidget {
  const _App({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: home),
    );
  }
}

Account account(int id, String name, String currency) => Account(
      id: id,
      name: name,
      type: AccountType.cash,
      currency: currency,
      openingBalance: 0,
      isArchived: false,
    );

final accounts = [account(1, 'Main', 'HKD'), account(2, 'US wallet', 'USD')];

const categories = [
  Category(id: 1, name: 'Food', type: CategoryType.expense),
  Category(id: 2, name: 'Salary', type: CategoryType.income),
];

final rule = RecurringRule(
  id: 1,
  type: TransactionType.expense,
  amount: 800000,
  accountId: 1,
  categoryId: 1,
  note: 'Rent',
  dayOfMonth: 5,
  startDate: DateTime(2026, 1, 1),
  isActive: true,
);

final pausedRule = RecurringRule(
  id: 2,
  type: TransactionType.transfer,
  amount: 100000,
  accountId: 1,
  toAccountId: 2,
  note: '',
  dayOfMonth: 20,
  startDate: DateTime(2026, 1, 1),
  isActive: false,
);

Future<void> pump(
  WidgetTester tester,
  Widget home, {
  required String language,
  List<RecurringRule> rules = const [],
  List<ExchangeRate> rates = const [],
}) async {
  tester.view.physicalSize = const Size(800, 3000);
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
        allAccountsProvider.overrideWith((ref) => Stream.value(accounts)),
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        transactionsProvider
            .overrideWith((ref) => Stream.value(const <TransactionRecord>[])),
        recurringRulesProvider.overrideWith((ref) => Stream.value(rules)),
        exchangeRatesProvider.overrideWith((ref) => Stream.value(rates)),
      ],
      child: _App(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

ExchangeRate rate(String currency, double value, {required bool manual}) {
  return ExchangeRate(
    currency: currency,
    rateToHkd: value,
    isManual: manual,
    updatedAt: DateTime(2026, 10, 5, 14, 30),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('Categories tab and form', () {
    testWidgets('English', (tester) async {
      await pump(tester, const CategoriesTab(), language: 'english');
      expect(find.text('Expense categories'), findsOneWidget);
      expect(find.text('Income categories'), findsOneWidget);

      await pump(tester, const CategoryFormPage(), language: 'english');
      expect(find.text('New category'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Category name'), findsOneWidget);
      expect(find.text('Choose an icon'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Traditional Chinese', (tester) async {
      await pump(tester, const CategoriesTab(), language: 'traditionalChinese');
      expect(find.text('支出分類'), findsOneWidget);
      expect(find.text('收入分類'), findsOneWidget);

      await pump(tester, const CategoryFormPage(), language: 'traditionalChinese');
      expect(find.text('新增分類'), findsOneWidget);
      expect(find.text('分類名稱'), findsOneWidget);
      expect(find.text('選一個圖示'), findsOneWidget);
      expect(find.text('儲存'), findsOneWidget);
    });

    testWidgets('Editing shows the edit title and delete button', (tester) async {
      await pump(tester, CategoryFormPage(existing: categories.first),
          language: 'english');
      expect(find.text('Edit category'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);

      await pump(tester, CategoryFormPage(existing: categories.first),
          language: 'traditionalChinese');
      expect(find.text('編輯分類'), findsOneWidget);
      expect(find.byTooltip('刪除'), findsOneWidget);
    });

    testWidgets('Validation: a name is required and duplicates are rejected',
        (tester) async {
      await pump(tester, const CategoryFormPage(), language: 'english');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name'), findsOneWidget);

      // Same name as an existing expense category, ignoring case
      await tester.enterText(find.byType(TextFormField), 'food');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('A category with this name already exists'), findsOneWidget);

      await pump(tester, const CategoryFormPage(), language: 'traditionalChinese');
      await tester.enterText(find.byType(TextFormField), 'FOOD');
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();
      expect(find.text('已經有同名的分類'), findsOneWidget);
    });
  });

  group('Recurring tab and form', () {
    testWidgets('English tab', (tester) async {
      await pump(tester, const RecurringTab(),
          language: 'english', rules: [rule, pausedRule]);

      expect(find.textContaining('Day 5 of each month'), findsOneWidget);
      expect(find.textContaining('Paused'), findsOneWidget);
      expect(find.text('Transfer: Main → US wallet'), findsOneWidget);
    });

    testWidgets('Traditional Chinese tab', (tester) async {
      await pump(tester, const RecurringTab(),
          language: 'traditionalChinese', rules: [rule, pausedRule]);

      expect(find.textContaining('每月 5 號'), findsOneWidget);
      expect(find.textContaining('已暫停'), findsOneWidget);
      expect(find.text('轉帳：Main → US wallet'), findsOneWidget);
    });

    testWidgets('The empty state is translated', (tester) async {
      await pump(tester, const RecurringTab(), language: 'english');
      expect(find.textContaining('No recurring items yet.'), findsOneWidget);

      await pump(tester, const RecurringTab(), language: 'traditionalChinese');
      expect(find.textContaining('還沒有固定收支'), findsOneWidget);
    });

    testWidgets('English form', (tester) async {
      await pump(tester, const RecurringFormPage(), language: 'english');

      expect(find.text('New recurring item'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Day of the month'), findsOneWidget);
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('Note (optional)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Traditional Chinese form and delete dialog', (tester) async {
      await pump(tester, RecurringFormPage(existing: rule),
          language: 'traditionalChinese');
      expect(find.text('編輯固定收支'), findsOneWidget);
      expect(find.text('每月幾號'), findsOneWidget);
      expect(find.text('開始日期'), findsOneWidget);

      await tester.tap(find.byTooltip('刪除'));
      await tester.pumpAndSettle();
      expect(find.text('刪除這個固定收支？'), findsOneWidget);
      expect(find.text('以後不會再自動新增。已經產生的交易會保留。'), findsOneWidget);
    });

    testWidgets('English delete dialog', (tester) async {
      await pump(tester, RecurringFormPage(existing: rule), language: 'english');
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this recurring item?'), findsOneWidget);
    });
  });

  group('Rates tab', () {
    final rates = [
      rate('USD', 7.8, manual: true),
      rate('JPY', 0.05, manual: false),
    ];

    testWidgets('English', (tester) async {
      await pump(tester, const RatesTab(), language: 'english', rates: rates);

      expect(find.textContaining('Rates marked Automatic update by themselves.'),
          findsOneWidget);
      expect(find.text('Update now'), findsOneWidget);
      expect(find.text('The app updates the rates when needed (at most once or twice a day).'),
          findsOneWidget);
      expect(find.text('Exchange rate data: ExchangeRate-API (exchangerate-api.com)'),
          findsOneWidget);
      // The US dollar account is in use; the rate was set by hand
      expect(find.text('In use'), findsOneWidget);
      expect(find.textContaining('Manual · updated'), findsOneWidget);
      expect(find.textContaining('Automatic · updated'), findsOneWidget);
      // A currency with no rate
      expect(find.text('No exchange rate set'), findsWidgets);
      expect(find.text('USD　US dollar'), findsOneWidget);
    });

    testWidgets('Traditional Chinese', (tester) async {
      await pump(tester, const RatesTab(),
          language: 'traditionalChinese', rates: rates);

      expect(find.textContaining('標示「自動」的匯率'), findsOneWidget);
      expect(find.text('立即更新'), findsOneWidget);
      expect(find.text('匯率資料來源：ExchangeRate-API (exchangerate-api.com)'),
          findsOneWidget);
      expect(find.text('使用中'), findsOneWidget);
      expect(find.textContaining('手動　更新於'), findsOneWidget);
      expect(find.textContaining('自動　更新於'), findsOneWidget);
      expect(find.text('USD　美元'), findsOneWidget);
    });

    testWidgets('A used currency without a rate is flagged', (tester) async {
      await pump(tester, const RatesTab(), language: 'english');
      expect(find.text('No exchange rate set (an account is using it)'),
          findsOneWidget);

      await pump(tester, const RatesTab(), language: 'traditionalChinese');
      expect(find.text('尚未設定匯率（有帳戶在使用）'), findsOneWidget);
    });

    testWidgets('The edit dialog is translated, and offers to switch back to automatic',
        (tester) async {
      await pump(tester, const RatesTab(), language: 'english', rates: rates);

      await tester.tap(find.text('USD　US dollar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Once saved, it is marked Manual'), findsOneWidget);
      expect(find.text('Switch back to automatic updates'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // An invalid rate is rejected with a translated message
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a rate greater than 0'), findsOneWidget);
    });

    testWidgets('Traditional Chinese edit dialog', (tester) async {
      await pump(tester, const RatesTab(), language: 'traditionalChinese', rates: rates);

      await tester.tap(find.text('USD　美元'));
      await tester.pumpAndSettle();
      expect(find.text('改回自動更新'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('儲存'), findsOneWidget);
    });
  });

  group('Update errors', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final zh = lookupAppLocalizations(const Locale('zh', 'TW'));

    test('Every kind of failure has a message in both languages', () {
      for (final error in RateFetchError.values) {
        expect(error.message(en, 503), isNotEmpty, reason: '$error');
        expect(error.message(zh, 503), isNotEmpty, reason: '$error');
        expect(error.message(en, 503), isNot(error.message(zh, 503)),
            reason: '$error');
      }
    });

    test('The server error shows its status code', () {
      const e = RateFetchException(RateFetchError.unavailable, 503);
      expect(e.message(en), contains('503'));
      expect(e.message(zh), '匯率服務暫時無法使用（503）');
    });

    test('Offline and timeout wording', () {
      expect(RateFetchError.offline.message(en), "Can't connect. Check your network.");
      expect(RateFetchError.offline.message(zh), '無法連線，請確認網路');
      expect(RateFetchError.timeout.message(zh), '連線逾時，請確認網路後再試');
    });
  });

  group('Credit card reminders', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final zh = lookupAppLocalizations(const Locale('zh', 'TW'));
    final due = DateTime(2026, 11, 5);

    test('Text in English', () {
      expect(en.notificationTitle, 'Credit card payment reminder');
      expect(
        NotificationService.dueSoonBody(en, 'Travel card (1234)', due),
        'Travel card (1234) is due on 11/5. Remember to have the funds ready.',
      );
      expect(
        NotificationService.dueTodayBody(en, 'Travel card (1234)'),
        'Today is the payment due date for Travel card (1234).',
      );
    });

    test('Text in Traditional Chinese', () {
      expect(zh.notificationTitle, '信用卡繳款提醒');
      expect(
        NotificationService.dueSoonBody(zh, 'Travel card (1234)', due),
        'Travel card (1234) 將於 11/5 繳款，記得準備資金',
      );
      expect(
        NotificationService.dueTodayBody(zh, 'Travel card (1234)'),
        '今天是 Travel card (1234) 的繳款日',
      );
    });

    test('The reminder language follows the language setting', () {
      const phoneInEnglish = [Locale('en', 'US')];
      const phoneInChinese = [Locale('zh', 'HK')];

      // Forced languages ignore the phone
      expect(localizationsFor(AppLanguage.english, phoneInChinese).localeName, 'en');
      expect(localizationsFor(AppLanguage.traditionalChinese, phoneInEnglish).localeName,
          'zh_TW');
      // Follow system uses the phone's language
      expect(localizationsFor(AppLanguage.system, phoneInEnglish).localeName, 'en');
      expect(localizationsFor(AppLanguage.system, phoneInChinese).localeName, 'zh_TW');
    });
  });
}
