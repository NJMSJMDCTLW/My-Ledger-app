import 'package:drift/drift.dart' show Value;
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';

/// The name to show for [category].
///
/// A built-in category (one with a `defaultKey`) is shown translated, so it follows the app
/// language. A category the user created, or a built-in one they renamed, shows the name stored
/// in the database.
String categoryDisplayName(AppLocalizations l10n, Category category) {
  return switch (category.defaultKey) {
    'food' => l10n.categoryFood,
    'transport' => l10n.categoryTransport,
    'shopping' => l10n.categoryShopping,
    'entertainment' => l10n.categoryEntertainment,
    'housing' => l10n.categoryHousing,
    'medical' => l10n.categoryMedical,
    'education' => l10n.categoryEducation,
    'otherExpense' => l10n.categoryOtherExpense,
    'salary' => l10n.categorySalary,
    'bonus' => l10n.categoryBonus,
    'otherIncome' => l10n.categoryOtherIncome,
    _ => category.name,
  };
}

/// Like [categoryDisplayName], but for a transaction that may have no category: "Uncategorized".
String categoryNameOrUncategorized(AppLocalizations l10n, Category? category) {
  return category == null ? l10n.uncategorized : categoryDisplayName(l10n, category);
}

/// What to write to the database when the user saves an edited category.
///
/// A built-in category is shown translated. If the user kept that name, only the icon is saved and
/// the category keeps following the app language. If they typed a different name, it becomes a
/// normal category with that name (its `defaultKey` is cleared). The type is never changed:
/// old transactions already recorded income or expense with this category.
CategoriesCompanion categoryEditCompanion({
  required AppLocalizations l10n,
  required Category existing,
  required String typedName,
  required String iconKey,
}) {
  final renamed = typedName != categoryDisplayName(l10n, existing);
  return renamed
      ? CategoriesCompanion(
          name: Value(typedName),
          defaultKey: const Value(null),
          icon: Value(iconKey),
        )
      : CategoriesCompanion(icon: Value(iconKey));
}
