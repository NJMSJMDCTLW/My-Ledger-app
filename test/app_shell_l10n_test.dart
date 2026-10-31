import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:hello_ledger/presentation/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real app shell wired up like main.dart, but without the background syncs
/// (notifications and network).
class _ShellApp extends ConsumerWidget {
  const _ShellApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (locales, supported) =>
          resolveSystemLocale(locales),
      home: const AppShell(),
    );
  }
}

/// Opens the app with no data in it. The database providers are replaced with empty streams, so
/// the test checks the screens' text without needing a database.
Future<void> pumpShell(WidgetTester tester, {required String language}) async {
  SharedPreferences.setMockInitialValues(
    {AppLanguageNotifier.storageKey: language},
  );
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allAccountsProvider
            .overrideWith((ref) => Stream.value(const <Account>[])),
        categoriesProvider
            .overrideWith((ref) => Stream.value(const <Category>[])),
        transactionsProvider
            .overrideWith((ref) => Stream.value(const <TransactionRecord>[])),
        exchangeRatesProvider
            .overrideWith((ref) => Stream.value(const <ExchangeRate>[])),
        recurringRulesProvider
            .overrideWith((ref) => Stream.value(const <RecurringRule>[])),
      ],
      child: const _ShellApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openDrawer(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('English: the app bar, home tab and drawer are in English',
      (tester) async {
    await pumpShell(tester, language: 'english');

    expect(find.text('My Ledger'), findsWidgets); // app bar title
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('No transactions this month'), findsOneWidget);
    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('總資產'), findsNothing);

    await openDrawer(tester, 'Open navigation menu');
    for (final label in [
      'Home',
      'Statistics',
      'Accounts',
      'Credit cards',
      'Recurring',
      'Categories',
      'Exchange rates',
      'Settings',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('首頁'), findsNothing);
  });

  testWidgets('Traditional Chinese: the same screens are in Chinese',
      (tester) async {
    await pumpShell(tester, language: 'traditionalChinese');

    expect(find.text('我的記帳本'), findsWidgets);
    expect(find.text('總資產'), findsOneWidget);
    expect(find.text('這個月還沒有交易'), findsOneWidget);
    expect(find.text('記一筆'), findsOneWidget);
    expect(find.text('收入'), findsOneWidget);
    expect(find.text('結餘'), findsOneWidget);
    expect(find.text('Total balance'), findsNothing);

    await openDrawer(tester, '開啟導覽選單');
    for (final label in [
      '首頁',
      '統計',
      '帳戶',
      '信用卡',
      '固定收支',
      '分類管理',
      '匯率',
      '設定',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Switching to the Settings tab shows its own title',
      (tester) async {
    await pumpShell(tester, language: 'english');

    await openDrawer(tester, 'Open navigation menu');
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // The app bar title changes from the app name to the tab name
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });
}
