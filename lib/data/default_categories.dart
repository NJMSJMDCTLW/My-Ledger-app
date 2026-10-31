import 'package:hello_ledger/data/enums.dart';

/// A built-in category that a new database starts with.
class DefaultCategory {
  const DefaultCategory(this.key, this.legacyName, this.type, this.iconKey);

  /// Stable code stored in `categories.default_key`. The translated name is looked up from it,
  /// so never rename a key that has been released.
  final String key;

  /// The Chinese name these categories were created with before they were translated. It is the
  /// text stored in `categories.name`, and what the upgrade matches to recognise an old row.
  final String legacyName;

  final CategoryType type;

  /// The icon (a key of `recommendedIcons`) used when the user has not picked another one.
  final String iconKey;
}

/// The built-in categories, in the order they are inserted. A fresh database gives them the ids
/// 1 to 11 in this order, which is how the upgrade finds them in an existing database: it
/// only trusts a row whose id, name and type all match.
const defaultCategories = [
  DefaultCategory('food', '餐飲', CategoryType.expense, 'restaurant'),
  DefaultCategory('transport', '交通', CategoryType.expense, 'bus'),
  DefaultCategory('shopping', '購物', CategoryType.expense, 'shopping'),
  DefaultCategory('entertainment', '娛樂', CategoryType.expense, 'games'),
  DefaultCategory('housing', '居住', CategoryType.expense, 'home'),
  DefaultCategory('medical', '醫療', CategoryType.expense, 'medical'),
  DefaultCategory('education', '教育', CategoryType.expense, 'school'),
  DefaultCategory('otherExpense', '其他', CategoryType.expense, 'more'),
  DefaultCategory('salary', '薪水', CategoryType.income, 'payments'),
  DefaultCategory('bonus', '獎金', CategoryType.income, 'gift'),
  DefaultCategory('otherIncome', '其他', CategoryType.income, 'more'),
];

/// The built-in category with this [key], or null for a key we do not know.
DefaultCategory? defaultCategoryByKey(String? key) {
  if (key == null) return null;
  for (final c in defaultCategories) {
    if (c.key == key) return c;
  }
  return null;
}
