import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:hello_ledger/presentation/transaction_form_page.dart';
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
      home: home,
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

final categories = [
  const Category(id: 1, name: 'Food', type: CategoryType.expense),
  const Category(id: 2, name: 'Salary', type: CategoryType.income),
];

final existing = TransactionRecord(
  id: 7,
  date: DateTime(2026, 10, 5),
  amount: 7800,
  type: TransactionType.expense,
  accountId: 1,
  categoryId: 1,
  originalAmount: 1000,
  originalCurrency: 'USD',
  note: 'Coffee',
  createdAt: DateTime(2026, 10, 5),
);

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps the transaction form. With [rates] empty, USD has no exchange rate.
Future<void> pumpForm(
  WidgetTester tester, {
  required String language,
  TransactionRecord? edit,
  List<Account>? withAccounts,
  bool usdRate = true,
}) async {
  useTallScreen(tester);
  SharedPreferences.setMockInitialValues(
    {AppLanguageNotifier.storageKey: language},
  );
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allAccountsProvider
            .overrideWith((ref) => Stream.value(withAccounts ?? accounts)),
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        transactionsProvider
            .overrideWith((ref) => Stream.value(const <TransactionRecord>[])),
        exchangeRatesProvider.overrideWith(
          (ref) => Stream.value([
            if (usdRate)
              ExchangeRate(
                currency: 'USD',
                rateToHkd: 7.8,
                isManual: true,
                updatedAt: DateTime(2026),
              ),
          ]),
        ),
      ],
      child: _App(home: TransactionFormPage(existing: edit)),
    ),
  );
  await tester.pumpAndSettle();
}


Future<void> choose(WidgetTester tester, String field, String option) async {
  await tester.tap(find.text(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  group('New transaction', () {
    testWidgets('English', (tester) async {
      await pumpForm(tester, language: 'english');


      expect(find.text('New transaction'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Entry currency (optional)'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Note (optional)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byTooltip('Calculator'), findsOneWidget);
    });

    testWidgets('Traditional Chinese', (tester) async {
      await pumpForm(tester, language: 'traditionalChinese');


      expect(find.text('新增交易'), findsOneWidget);
      expect(find.text('支出'), findsOneWidget);
      expect(find.text('收入'), findsOneWidget);
      expect(find.text('轉帳'), findsOneWidget);
      expect(find.text('金額'), findsOneWidget);
      expect(find.text('帳戶'), findsOneWidget);
      expect(find.text('輸入貨幣（選填）'), findsOneWidget);
      expect(find.text('類別'), findsOneWidget);
      expect(find.text('日期'), findsOneWidget);
      expect(find.text('備註（選填）'), findsOneWidget);
      expect(find.text('儲存'), findsOneWidget);
      expect(find.byTooltip('計算機'), findsOneWidget);
    });

    testWidgets('Validation errors follow the language', (tester) async {
      await pumpForm(tester, language: 'english');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter an amount greater than 0'), findsOneWidget);
      expect(find.text('Select an account'), findsOneWidget);
      expect(find.text('Select a category'), findsOneWidget);

      await pumpForm(tester, language: 'traditionalChinese');
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();
      expect(find.text('請輸入大於 0 的金額'), findsOneWidget);
      expect(find.text('請選擇帳戶'), findsOneWidget);
      expect(find.text('請選擇類別'), findsOneWidget);
    });

    testWidgets('Without any account it asks to add one first', (tester) async {
      await pumpForm(tester, language: 'english', withAccounts: const []);
      expect(find.text('Add an account first'), findsOneWidget);

      await pumpForm(tester,
          language: 'traditionalChinese', withAccounts: const []);
      expect(find.text('請先新增一個帳戶'), findsOneWidget);
    });
  });

  group('Calculator', () {
    testWidgets('English: opens from the calculator icon and fills the amount',
        (tester) async {
      await pumpForm(tester, language: 'english');

      await tester.tap(find.byTooltip('Calculator'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);

      // 12 + 3 x 4 = 24
      for (final key in ['1', '2', '+', '3', '×', '4']) {
        await tester.tap(find.text(key));
        await tester.pump();
      }
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('24.00'), findsOneWidget);
      expect(find.text('Done'), findsNothing); // the sheet closed
    });

    testWidgets('Traditional Chinese: the Done button is translated',
        (tester) async {
      await pumpForm(tester, language: 'traditionalChinese');

      await tester.tap(find.byTooltip('計算機'));
      await tester.pumpAndSettle();
      expect(find.text('完成'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });
  });

  group('Transfers', () {
    testWidgets('English: from and to accounts, and the received amount between currencies',
        (tester) async {
      await pumpForm(tester, language: 'english');

      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();
      expect(find.text('From account'), findsOneWidget);
      expect(find.text('To account'), findsOneWidget);
      // A transfer has no category or entry currency
      expect(find.text('Category'), findsNothing);
      expect(find.text('Entry currency (optional)'), findsNothing);

      await choose(tester, 'From account', 'Main');
      await choose(tester, 'To account', 'US wallet');

      // HKD -> USD: the received amount has to be filled in or estimated
      expect(find.text('Amount received (USD)'), findsOneWidget);
      expect(
        find.text(
          'The exchange rates for these two currencies are not set. Enter the amount that was actually received.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Traditional Chinese', (tester) async {
      await pumpForm(tester, language: 'traditionalChinese');

      await tester.tap(find.text('轉帳'));
      await tester.pumpAndSettle();
      expect(find.text('轉出帳戶'), findsOneWidget);
      expect(find.text('轉入帳戶'), findsOneWidget);

      await choose(tester, '轉出帳戶', 'Main');
      await choose(tester, '轉入帳戶', 'US wallet');
      expect(find.text('轉入金額（USD）'), findsOneWidget);
    });

    testWidgets('Transferring to the same account is rejected', (tester) async {
      await pumpForm(tester, language: 'english');
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      await choose(tester, 'From account', 'Main');
      await choose(tester, 'To account', 'Main');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text("You can't transfer to the same account"), findsOneWidget);
    });
  });

  group('Entry currency', () {
    /// Types 10 with the calculator, records to the HKD account and enters it in US dollars.
    Future<void> enterTenUsd(WidgetTester tester, String accountField,
        String entryField, String calculatorTooltip, String done,
        String usdName) async {
      await choose(tester, accountField, 'Main');
      await tester.tap(find.byTooltip(calculatorTooltip));
      await tester.pumpAndSettle();
      for (final key in ['1', '0']) {
        await tester.tap(find.text(key));
        await tester.pump();
      }
      await tester.tap(find.text(done));
      await tester.pumpAndSettle();

      await tester.tap(find.text(entryField));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(usdName).last);
      await tester.pumpAndSettle();
    }

    testWidgets('English: picking US dollars shows the converted amount',
        (tester) async {
      await pumpForm(tester, language: 'english');
      await enterTenUsd(tester, 'Account', 'Entry currency (optional)',
          'Calculator', 'Done', 'US dollar');

      // 10 USD x 7.8 = HK$78.00
      expect(find.text('Converts to HK\$78.00 in the account'), findsOneWidget);
    });

    testWidgets('Traditional Chinese: the converted amount message',
        (tester) async {
      await pumpForm(tester, language: 'traditionalChinese');
      await enterTenUsd(tester, '帳戶', '輸入貨幣（選填）', '計算機', '完成', '美元');

      expect(find.text('折合 HK\$78.00，記在帳戶裡'), findsOneWidget);
    });

    testWidgets('Without an exchange rate it says it cannot convert',
        (tester) async {
      await pumpForm(tester, language: 'english', usdRate: false);
      await enterTenUsd(tester, 'Account', 'Entry currency (optional)',
          'Calculator', 'Done', 'US dollar');

      expect(find.text("No exchange rate yet, so it can't be converted"),
          findsOneWidget);
    });

    testWidgets('The default option names the account currency', (tester) async {
      await pumpForm(tester, language: 'english');

      await choose(tester, 'Account', 'Main');
      expect(find.text('Same as the account (HKD)'), findsOneWidget);
    });

    testWidgets('Chinese wording for the default option', (tester) async {
      await pumpForm(tester, language: 'traditionalChinese');

      await choose(tester, '帳戶', 'Main');
      expect(find.text('與帳戶相同（HKD）'), findsOneWidget);
    });
  });

  group('Editing', () {
    testWidgets('English: title, original amount, date and delete', (tester) async {
      await pumpForm(tester, language: 'english', edit: existing);

      expect(find.text('Edit transaction'), findsOneWidget);
      // Entered in USD: the original amount is shown
      expect(find.text('10.00'), findsOneWidget);
      expect(find.text('10/5/2026'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this transaction?'), findsOneWidget);
      expect(find.text("This can't be undone."), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Traditional Chinese: the date uses the Chinese format and delete dialog',
        (tester) async {
      await pumpForm(tester, language: 'traditionalChinese', edit: existing);

      expect(find.text('編輯交易'), findsOneWidget);
      expect(find.text('2026/10/5'), findsOneWidget);

      await tester.tap(find.byTooltip('刪除'));
      await tester.pumpAndSettle();
      expect(find.text('刪除這筆交易？'), findsOneWidget);
      expect(find.text('刪除後無法復原。'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });
  });
}
