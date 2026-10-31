import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/category_names.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/default_categories.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:hello_ledger/presentation/category_form_page.dart';
import 'package:hello_ledger/presentation/tabs/categories_tab.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A built-in category as a fresh or upgraded database stores it.
Category builtIn(int index) {
  final d = defaultCategories[index];
  return Category(id: index + 1, name: d.legacyName, type: d.type, defaultKey: d.key);
}

/// A category the user created.
const travel = Category(id: 12, name: '旅行', type: CategoryType.expense);

final en = lookupAppLocalizations(const Locale('en'));
final zh = lookupAppLocalizations(const Locale('zh', 'TW'));

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

Future<void> pump(
  WidgetTester tester,
  Widget home, {
  required String language,
  required List<Category> categories,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Start from an empty tree, so a screen opened earlier in the same test is not reused
  await tester.pumpWidget(const SizedBox());

  SharedPreferences.setMockInitialValues(
    {AppLanguageNotifier.storageKey: language},
  );
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
      ],
      child: _App(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('Display names', () {
    test('Every built-in category has an English and a Chinese name', () {
      for (var i = 0; i < defaultCategories.length; i++) {
        final c = builtIn(i);
        expect(categoryDisplayName(en, c), isNotEmpty);
        expect(categoryDisplayName(zh, c), isNotEmpty);
        // The Chinese name is the one the category was created with
        expect(categoryDisplayName(zh, c), defaultCategories[i].legacyName);
      }
    });

    test('The English names', () {
      final names = [for (var i = 0; i < 11; i++) categoryDisplayName(en, builtIn(i))];
      expect(names, [
        'Food',
        'Transport',
        'Shopping',
        'Entertainment',
        'Housing',
        'Medical',
        'Education',
        'Other',
        'Salary',
        'Bonus',
        'Other',
      ]);
    });

    test('A category the user created keeps the name they typed, in any language', () {
      expect(categoryDisplayName(en, travel), '旅行');
      expect(categoryDisplayName(zh, travel), '旅行');
    });

    test('A built-in category the user renamed keeps its new name', () {
      const renamed = Category(id: 1, name: 'Snacks', type: CategoryType.expense);
      expect(categoryDisplayName(zh, renamed), 'Snacks');
    });

    test('An unknown key falls back to the stored name', () {
      const future = Category(
        id: 1,
        name: 'Pets',
        type: CategoryType.expense,
        defaultKey: 'somethingNew',
      );
      expect(categoryDisplayName(en, future), 'Pets');
    });

    test('No category is shown as uncategorized', () {
      expect(categoryNameOrUncategorized(en, null), 'Uncategorized');
      expect(categoryNameOrUncategorized(zh, null), '未分類');
      expect(categoryNameOrUncategorized(en, builtIn(0)), 'Food');
    });
  });

  group('Icons', () {
    test('A built-in category uses its own icon until the user picks another', () {
      expect(categoryIconKey(builtIn(0)), 'restaurant');
      expect(categoryIconKey(builtIn(8)), 'payments');
      final picked = builtIn(0).copyWith(icon: const Value('flight'));
      expect(categoryIconKey(picked), 'flight');
    });

    test('A created category without an icon gets the neutral one', () {
      expect(categoryIconKey(travel), 'more');
    });
  });

  group('Saving an edited category', () {
    test('Keeping the shown name only saves the icon, and it keeps following the language', () {
      final update = categoryEditCompanion(
        l10n: en,
        existing: builtIn(0),
        typedName: 'Food', // what the English screen showed
        iconKey: 'coffee',
      );
      expect(update.name.present, isFalse);
      expect(update.defaultKey.present, isFalse);
      expect(update.icon.value, 'coffee');
    });

    test('Typing a different name turns it into a normal category', () {
      final update = categoryEditCompanion(
        l10n: en,
        existing: builtIn(0),
        typedName: 'Snacks',
        iconKey: 'restaurant',
      );
      expect(update.name.value, 'Snacks');
      expect(update.defaultKey.present, isTrue);
      expect(update.defaultKey.value, isNull); // cleared
    });

    test('The name check uses the language of the screen', () {
      // On the Chinese screen the shown name is 餐飲, so "Food" counts as a new name
      final update = categoryEditCompanion(
        l10n: zh,
        existing: builtIn(0),
        typedName: 'Food',
        iconKey: 'restaurant',
      );
      expect(update.name.value, 'Food');
      expect(update.defaultKey.value, isNull);
    });

    test('Editing a category the user created only needs the icon when the name is unchanged', () {
      final update = categoryEditCompanion(
        l10n: en,
        existing: travel,
        typedName: '旅行',
        iconKey: 'flight',
      );
      expect(update.name.present, isFalse);
      expect(update.icon.value, 'flight');
    });
  });

  group('Screens', () {
    final categories = [builtIn(0), builtIn(8), travel];

    testWidgets('The categories tab shows built-in names in the app language',
        (tester) async {
      await pump(tester, const CategoriesTab(),
          language: 'english', categories: categories);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('旅行'), findsOneWidget); // typed by the user
      expect(find.text('餐飲'), findsNothing);

      await pump(tester, const CategoriesTab(),
          language: 'traditionalChinese', categories: categories);
      expect(find.text('餐飲'), findsOneWidget);
      expect(find.text('薪水'), findsOneWidget);
      expect(find.text('旅行'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('Editing a built-in category shows the translated name',
        (tester) async {
      await pump(tester, CategoryFormPage(existing: builtIn(0)),
          language: 'english', categories: categories);
      expect(find.widgetWithText(TextFormField, 'Food'), findsOneWidget);

      await pump(tester, CategoryFormPage(existing: builtIn(0)),
          language: 'traditionalChinese', categories: categories);
      expect(find.widgetWithText(TextFormField, '餐飲'), findsOneWidget);
    });

    testWidgets('A new name clashes with the built-in name the user sees',
        (tester) async {
      await pump(tester, const CategoryFormPage(),
          language: 'english', categories: categories);
      await tester.enterText(find.byType(TextFormField), 'food');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('A category with this name already exists'), findsOneWidget);

      // In Chinese the built-in name is 餐飲
      await pump(tester, const CategoryFormPage(),
          language: 'traditionalChinese', categories: categories);
      await tester.enterText(find.byType(TextFormField), '餐飲');
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();
      expect(find.text('已經有同名的分類'), findsOneWidget);
    });

    testWidgets('The other language name is free to use', (tester) async {
      // On the English screen, "餐飲" is not an existing name (Food is), so it passes validation.
      // Save would then write to the database, so only check that no error is shown by validating.
      await pump(tester, const CategoryFormPage(),
          language: 'english', categories: categories);
      await tester.enterText(find.byType(TextFormField), '餐飲');
      final form = tester.state<FormState>(find.byType(Form));
      expect(form.validate(), isTrue);
    });
  });
}
