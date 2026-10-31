import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:hello_ledger/presentation/tabs/settings_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A minimal app that wires the language setting the same way main.dart does.
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (locales, supported) =>
          resolveSystemLocale(locales),
      home: const Scaffold(body: SettingsTab()),
    );
  }
}

Future<ProviderContainer> pumpSettings(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
}) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const _TestApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Starts in English and follows the system when nothing is saved',
      (tester) async {
    final container = await pumpSettings(tester);

    // The test device language is English
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Follow system'), findsOneWidget);
    expect(container.read(appLanguageProvider), AppLanguage.system);
  });

  testWidgets('Choosing Traditional Chinese switches the screen and is saved',
      (tester) async {
    final container = await pumpSettings(tester);

    await tester.tap(find.text('繁體中文'));
    await tester.pumpAndSettle();

    expect(find.text('語言'), findsOneWidget);
    expect(find.text('跟隨系統'), findsOneWidget);
    expect(find.text('Language'), findsNothing);
    expect(container.read(appLanguageProvider), AppLanguage.traditionalChinese);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppLanguageNotifier.storageKey), 'traditionalChinese');
  });

  testWidgets('Choosing English switches back', (tester) async {
    await pumpSettings(tester, saved: {AppLanguageNotifier.storageKey: 'traditionalChinese'});
    expect(find.text('語言'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('語言'), findsNothing);
  });

  testWidgets('A saved language is restored when the app starts',
      (tester) async {
    final container = await pumpSettings(
      tester,
      saved: {AppLanguageNotifier.storageKey: 'traditionalChinese'},
    );

    expect(container.read(appLanguageProvider), AppLanguage.traditionalChinese);
    expect(find.text('語言'), findsOneWidget);
  });

  testWidgets('The selected option is marked', (tester) async {
    await pumpSettings(tester, saved: {AppLanguageNotifier.storageKey: 'english'});

    final radios = tester.widgetList<RadioListTile<AppLanguage>>(
      find.byType(RadioListTile<AppLanguage>),
    );
    final selected = radios.where((r) => r.value == AppLanguage.english);
    expect(selected, hasLength(1));
    expect(tester.widget<RadioGroup<AppLanguage>>(find.byType(RadioGroup<AppLanguage>)).groupValue,
        AppLanguage.english);
  });
}
