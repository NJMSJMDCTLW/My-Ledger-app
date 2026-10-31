import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hello_ledger/data/default_categories.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, RecurringRules, ExchangeRates],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'ledger'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
        },
        onUpgrade: (m, from, to) async {
          // v1 -> v2: add the recurring rules table; existing data is untouched
          if (from < 2) await m.createTable(recurringRules);
          // v2 -> v3: multi-currency. Add the exchange rates table and the transfer "to amount" column
          if (from < 3) {
            // This table is created in its latest shape, so it already includes the v4 isManual column
            await m.createTable(exchangeRates);
            await m.addColumn(transactions, transactions.toAmount);
          }
          // v3 -> v4: exchange rates can update automatically. The v3 rates were all entered by the user, so mark them manual
          // so the first automatic update does not overwrite them
          if (from == 3) {
            await m.addColumn(exchangeRates, exchangeRates.isManual);
            await customStatement('UPDATE exchange_rates SET is_manual = 1');
          }
          // v4 -> v5: a transaction can be entered in another currency; keep the original amount and currency
          if (from < 5) {
            await m.addColumn(transactions, transactions.originalAmount);
            await m.addColumn(transactions, transactions.originalCurrency);
          }
          // v5 -> v6: the built-in categories get a stable key, so their names can be translated
          if (from < 6) {
            await m.addColumn(categories, categories.defaultKey);
            await _tagDefaultCategories();
          }
        },
      );

  Future<void> _seedCategories() async {
    await batch((b) {
      b.insertAll(categories, [
        for (final c in defaultCategories)
          CategoriesCompanion.insert(
            name: c.legacyName,
            type: c.type,
            defaultKey: Value(c.key),
          ),
      ]);
    });
  }

  /// Gives the built-in categories of an existing database their key.
  ///
  /// A fresh install creates them with the ids 1 to 11 in the order of [defaultCategories], and
  /// they were named in Chinese. Only a row whose id, name and type all still match is tagged: a
  /// built-in category the user has renamed, and any category the user created, keep being plain
  /// categories with their own name.
  Future<void> _tagDefaultCategories() async {
    for (var i = 0; i < defaultCategories.length; i++) {
      final c = defaultCategories[i];
      await customUpdate(
        'UPDATE categories SET default_key = ? WHERE id = ? AND name = ? AND type = ?',
        variables: [
          Variable.withString(c.key),
          Variable.withInt(i + 1),
          Variable.withString(c.legacyName),
          Variable.withInt(c.type.index),
        ],
        updates: {categories},
      );
    }
  }
}
