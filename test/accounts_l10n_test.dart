import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:hello_ledger/presentation/account_form_page.dart';
import 'package:hello_ledger/presentation/tabs/accounts_tab.dart';
import 'package:hello_ledger/presentation/tabs/credit_cards_tab.dart';
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

Account account(
  int id,
  String name,
  AccountType type, {
  String currency = 'HKD',
  int opening = 0,
  bool archived = false,
  int? limit,
  int? statementDay,
  int? dueDay,
  String? last4,
}) {
  return Account(
    id: id,
    name: name,
    type: type,
    currency: currency,
    openingBalance: opening,
    isArchived: archived,
    creditLimit: limit,
    statementDay: statementDay,
    dueDay: dueDay,
    last4: last4,
  );
}

/// Pumps [home] with the given accounts, no transactions, and a USD rate of 7.8.
Future<void> pump(
  WidgetTester tester,
  Widget home, {
  required String language,
  List<Account> accounts = const [],
}) async {
  SharedPreferences.setMockInitialValues(
    {AppLanguageNotifier.storageKey: language},
  );
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allAccountsProvider.overrideWith((ref) => Stream.value(accounts)),
        categoriesProvider
            .overrideWith((ref) => Stream.value(const <Category>[])),
        transactionsProvider
            .overrideWith((ref) => Stream.value(const <TransactionRecord>[])),
        exchangeRatesProvider.overrideWith(
          (ref) => Stream.value([
            ExchangeRate(
              currency: 'USD',
              rateToHkd: 7.8,
              isManual: true,
              updatedAt: DateTime(2026),
            ),
          ]),
        ),
      ],
      child: _App(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Due in 3 days, so the card shows "in 3 days" and the payment reminder
  final dueDay = DateTime.now().add(const Duration(days: 3)).day;
  final statementDay = DateTime.now().add(const Duration(days: 10)).day;

  final accounts = [
    account(1, 'Main', AccountType.bank, opening: 100000),
    account(
      2,
      'Travel card',
      AccountType.creditCard,
      currency: 'USD',
      opening: -20000, // US$200 debt
      limit: 100000, // US$1,000 limit
      dueDay: dueDay,
      statementDay: statementDay,
      last4: '1234',
    ),
    account(3, 'Old wallet', AccountType.eWallet, archived: true),
  ];

  group('Accounts tab', () {
    testWidgets('English', (tester) async {
      await pump(tester, const AccountsTab(),
          language: 'english', accounts: accounts);

      expect(find.text('Bank account'), findsOneWidget);
      expect(find.text('Credit card · USD'), findsOneWidget);
      expect(find.text('Archived accounts'), findsOneWidget);
      expect(find.text('E-wallet'), findsOneWidget);
      // The foreign-currency account shows its HKD equivalent: -US$200 x 7.8
      expect(find.text('-US\$200.00'), findsOneWidget);
      expect(find.text('≈ -HK\$1,560.00'), findsOneWidget);
      expect(find.text('銀行帳戶'), findsNothing);
    });

    testWidgets('Traditional Chinese', (tester) async {
      await pump(tester, const AccountsTab(),
          language: 'traditionalChinese', accounts: accounts);

      expect(find.text('銀行帳戶'), findsOneWidget);
      expect(find.text('信用卡 · USD'), findsOneWidget);
      expect(find.text('已封存帳戶'), findsOneWidget);
      expect(find.text('電子錢包'), findsOneWidget);
      expect(find.text('Bank account'), findsNothing);
    });

    testWidgets('The empty state is translated', (tester) async {
      await pump(tester, const AccountsTab(), language: 'english');
      expect(
        find.text('No accounts yet. Tap the button at the bottom right to add one.'),
        findsOneWidget,
      );

      await pump(tester, const AccountsTab(), language: 'traditionalChinese');
      expect(find.text('還沒有帳戶，點右下角新增'), findsOneWidget);
    });

    testWidgets('A foreign account without a rate says so', (tester) async {
      final noRate = [
        account(1, 'Yen', AccountType.cash, currency: 'JPY', opening: 100),
      ];
      await pump(tester, const AccountsTab(),
          language: 'english', accounts: noRate);
      expect(find.text('No exchange rate set'), findsOneWidget);

      await pump(tester, const AccountsTab(),
          language: 'traditionalChinese', accounts: noRate);
      expect(find.text('尚未設定匯率'), findsOneWidget);
    });
  });

  group('Credit cards tab', () {
    testWidgets('English', (tester) async {
      await pump(tester, const CreditCardsTab(),
          language: 'english', accounts: accounts);

      expect(find.text('Credit cards'), findsOneWidget);
      expect(find.text('Travel card (1234)'), findsOneWidget);
      expect(find.text('Debt US\$200.00'), findsOneWidget);
      expect(find.text('Available US\$800.00 / US\$1,000.00'), findsOneWidget);
      expect(find.textContaining('Next statement:'), findsOneWidget);
      expect(find.textContaining('in 10 days'), findsOneWidget);
      // Due in 3 days with debt: the reminder is appended
      expect(find.textContaining('(in 3 days) ⚠ Remember to pay'), findsOneWidget);
    });

    testWidgets('Traditional Chinese', (tester) async {
      await pump(tester, const CreditCardsTab(),
          language: 'traditionalChinese', accounts: accounts);

      expect(find.text('信用卡'), findsOneWidget);
      expect(find.text('欠款 US\$200.00'), findsOneWidget);
      expect(find.text('可用額度 US\$800.00 / US\$1,000.00'), findsOneWidget);
      expect(find.textContaining('下次結帳：'), findsOneWidget);
      expect(find.textContaining('（10 天後）'), findsOneWidget);
      expect(find.textContaining('（3 天後） ⚠ 記得繳款'), findsOneWidget);
    });

    testWidgets('Unset statement and due days are explained', (tester) async {
      final bare = [account(1, 'Card', AccountType.creditCard)];
      await pump(tester, const CreditCardsTab(),
          language: 'english', accounts: bare);
      expect(find.text('Statement day: not set'), findsOneWidget);
      expect(find.text('Due day: not set'), findsOneWidget);

      await pump(tester, const CreditCardsTab(),
          language: 'traditionalChinese', accounts: bare);
      expect(find.text('結帳日：未設定'), findsOneWidget);
      expect(find.text('繳款日：未設定'), findsOneWidget);
    });

    testWidgets('The empty state is translated', (tester) async {
      await pump(tester, const CreditCardsTab(), language: 'english');
      expect(
        find.text('No credit cards yet. Tap the button at the bottom right to add one.'),
        findsOneWidget,
      );
    });

    testWidgets('A due date more than 7 days away shows no reminder',
        (tester) async {
      final far = [
        account(
          1,
          'Card',
          AccountType.creditCard,
          opening: -100,
          dueDay: DateTime.now().add(const Duration(days: 15)).day,
        ),
      ];
      await pump(tester, const CreditCardsTab(),
          language: 'english', accounts: far);
      expect(find.textContaining('Remember to pay'), findsNothing);
    });
  });

  group('Account form', () {
    /// The credit card form is long; a tall screen builds every field, including the Save button.
    void useTallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('English', (tester) async {
      useTallScreen(tester);
      await pump(
        tester,
        const AccountFormPage(initialType: AccountType.creditCard),
        language: 'english',
      );

      expect(find.text('Add account'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Current debt'), findsOneWidget);
      expect(find.text('Credit limit'), findsOneWidget);
      expect(find.text('Statement day (day of month)'), findsOneWidget);
      expect(find.text('Due day (day of month)'), findsOneWidget);
      expect(find.text('Last 4 digits of the card number'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Traditional Chinese', (tester) async {
      useTallScreen(tester);
      await pump(
        tester,
        const AccountFormPage(initialType: AccountType.creditCard),
        language: 'traditionalChinese',
      );

      expect(find.text('新增帳戶'), findsOneWidget);
      expect(find.text('名稱'), findsOneWidget);
      expect(find.text('類型'), findsOneWidget);
      expect(find.text('貨幣'), findsOneWidget);
      expect(find.text('目前欠款'), findsOneWidget);
      expect(find.text('信用額度'), findsOneWidget);
      expect(find.text('結帳日（每月幾號）'), findsOneWidget);
      expect(find.text('繳款日（每月幾號）'), findsOneWidget);
      expect(find.text('卡號末四碼'), findsOneWidget);
      expect(find.text('儲存'), findsOneWidget);
    });

    testWidgets('Validation messages follow the language', (tester) async {
      await pump(tester, const AccountFormPage(), language: 'english');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name'), findsOneWidget);

      await pump(tester, const AccountFormPage(), language: 'traditionalChinese');
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();
      expect(find.text('請輸入名稱'), findsOneWidget);
    });

    testWidgets('Editing shows the archive tooltip and the locked-currency hint',
        (tester) async {
      await pump(
        tester,
        AccountFormPage(existing: accounts.first),
        language: 'english',
        accounts: accounts,
      );
      expect(find.text('Edit account'), findsOneWidget);
      expect(find.byTooltip('Archive'), findsOneWidget);
      expect(
        find.text("An account that already has records can't change its currency."),
        findsOneWidget,
      );
    });
  });
}
