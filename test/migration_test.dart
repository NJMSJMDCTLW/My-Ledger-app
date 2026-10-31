import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/default_categories.dart';
import 'package:hello_ledger/data/enums.dart';

/// The categories table as it was before version 6 (no default_key column), with the 11 built-in
/// categories a fresh install had created. A real old database always has it.
void createCategoriesBeforeV6(dynamic raw, {List<String> extra = const []}) {
  raw.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type INTEGER NOT NULL,
      icon TEXT NULL,
      color INTEGER NULL
    );
  ''');
  const expense = ['餐飲', '交通', '購物', '娛樂', '居住', '醫療', '教育', '其他'];
  const income = ['薪水', '獎金', '其他'];
  for (final name in expense) {
    raw.execute("INSERT INTO categories (name, type) VALUES ('$name', 0)");
  }
  for (final name in income) {
    raw.execute("INSERT INTO categories (name, type) VALUES ('$name', 1)");
  }
  for (final statement in extra) {
    raw.execute(statement);
  }
}

void main() {
  test('Upgrade from version 2 to 3: old data is kept, and the new column and rates table work', () async {
    // Build a version 2 database by hand (transactions has no to_amount yet, and there is no exchange_rates table)
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE accounts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type INTEGER NOT NULL,
              currency TEXT NOT NULL DEFAULT 'HKD',
              opening_balance INTEGER NOT NULL DEFAULT 0,
              is_archived INTEGER NOT NULL DEFAULT 0,
              credit_limit INTEGER NULL,
              statement_day INTEGER NULL,
              due_day INTEGER NULL,
              last4 TEXT NULL
            );
          ''');
          raw.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date INTEGER NOT NULL,
              amount INTEGER NOT NULL,
              type INTEGER NOT NULL,
              account_id INTEGER NOT NULL,
              to_account_id INTEGER NULL,
              category_id INTEGER NULL,
              note TEXT NOT NULL DEFAULT '',
              created_at INTEGER NOT NULL DEFAULT 0
            );
          ''');
          raw.execute(
              "INSERT INTO accounts (name, type, opening_balance) VALUES ('現金', 1, 5000)");
          raw.execute('''
            INSERT INTO transactions (date, amount, type, account_id, note)
            VALUES (1790000000, 1234, 0, 1, '午餐')
          ''');
          createCategoriesBeforeV6(raw);
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);

    // Old data is still there, and the new column is null
    final accounts = await db.select(db.accounts).get();
    expect(accounts.single.name, '現金');
    expect(accounts.single.currency, 'HKD');
    expect(accounts.single.openingBalance, 5000);

    final txs = await db.select(db.transactions).get();
    expect(txs.single.amount, 1234);
    expect(txs.single.note, '午餐');
    expect(txs.single.toAmount, isNull);

    // The new rates table works
    await db.into(db.exchangeRates).insert(
          ExchangeRatesCompanion.insert(currency: 'USD', rateToHkd: 7.8),
        );
    final rates = await db.select(db.exchangeRates).get();
    expect(rates.single.currency, 'USD');
    expect(rates.single.rateToHkd, 7.8);

    // The new column can be written
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            date: DateTime(2026, 10, 1),
            amount: 78000,
            type: TransactionType.transfer,
            accountId: 1,
          ),
        );
  });

  test('Upgrade from version 3 to 4: existing rates are kept and marked manual', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // The version 3 rates table: no is_manual column yet
          raw.execute('''
            CREATE TABLE exchange_rates (
              currency TEXT NOT NULL PRIMARY KEY,
              rate_to_hkd REAL NOT NULL,
              updated_at INTEGER NOT NULL DEFAULT 0
            );
          ''');
          raw.execute(
              "INSERT INTO exchange_rates (currency, rate_to_hkd, updated_at) VALUES ('USD', 7.8, 1790000000)");
          // A real version 3 database always has the transactions table (already with to_amount), and the upgrade keeps adding columns to it
          raw.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date INTEGER NOT NULL,
              amount INTEGER NOT NULL,
              type INTEGER NOT NULL,
              account_id INTEGER NOT NULL,
              to_account_id INTEGER NULL,
              to_amount INTEGER NULL,
              category_id INTEGER NULL,
              note TEXT NOT NULL DEFAULT '',
              created_at INTEGER NOT NULL DEFAULT 0
            );
          ''');
          createCategoriesBeforeV6(raw);
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(db.close);

    final rates = await db.select(db.exchangeRates).get();
    expect(rates.single.currency, 'USD');
    expect(rates.single.rateToHkd, 7.8);
    // A rate the user entered themselves counts as manual after the upgrade, so the first automatic update does not overwrite it
    expect(rates.single.isManual, isTrue);
  });

  test('Upgrade from version 4 to 5: old transactions are kept, and the original amount and currency are null', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date INTEGER NOT NULL,
              amount INTEGER NOT NULL,
              type INTEGER NOT NULL,
              account_id INTEGER NOT NULL,
              to_account_id INTEGER NULL,
              to_amount INTEGER NULL,
              category_id INTEGER NULL,
              note TEXT NOT NULL DEFAULT '',
              created_at INTEGER NOT NULL DEFAULT 0
            );
          ''');
          raw.execute('''
            INSERT INTO transactions (date, amount, type, account_id, note)
            VALUES (1790000000, 777, 0, 1, '舊交易')
          ''');
          createCategoriesBeforeV6(raw);
          raw.execute('PRAGMA user_version = 4');
        },
      ),
    );
    addTearDown(db.close);

    final txs = await db.select(db.transactions).get();
    expect(txs.single.amount, 777);
    expect(txs.single.note, '舊交易');
    expect(txs.single.originalAmount, isNull);
    expect(txs.single.originalCurrency, isNull);
  });

  group('Upgrade from version 5 to 6: built-in categories get a key', () {
    /// Opens a version 5 database whose categories table has been set up by [extra] statements.
    AppDatabase openV5({List<String> extra = const []}) {
      return AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            createCategoriesBeforeV6(raw, extra: extra);
            raw.execute('PRAGMA user_version = 5');
          },
        ),
      );
    }

    Future<Map<int, Category>> load(AppDatabase db) async {
      return {for (final c in await db.select(db.categories).get()) c.id: c};
    }

    test('The 11 built-in categories are tagged, in order, and keep their names', () async {
      final db = openV5();
      addTearDown(db.close);
      final cats = await load(db);

      expect(cats.length, 11);
      for (var i = 0; i < defaultCategories.length; i++) {
        final c = cats[i + 1]!;
        expect(c.defaultKey, defaultCategories[i].key, reason: 'id ${i + 1}');
        expect(c.name, defaultCategories[i].legacyName); // the stored name is untouched
      }
      // Two categories are both called "Other": each gets the key of its own type
      expect(cats[8]!.defaultKey, 'otherExpense');
      expect(cats[11]!.defaultKey, 'otherIncome');
    });

    test('A built-in category the user renamed, and the categories they created, stay plain',
        () async {
      final db = openV5(extra: [
        "UPDATE categories SET name = '吃的' WHERE id = 1", // renamed a built-in one
        "INSERT INTO categories (id, name, type) VALUES (12, '餐飲', 0)", // created "餐飲" themselves
        "INSERT INTO categories (id, name, type) VALUES (13, '旅行', 0)",
      ]);
      addTearDown(db.close);
      final cats = await load(db);

      expect(cats[1]!.defaultKey, isNull);
      expect(cats[1]!.name, '吃的');
      expect(cats[12]!.defaultKey, isNull); // same name as a built-in one, but not the built-in id
      expect(cats[13]!.defaultKey, isNull);
      // Everything else is still tagged
      expect(cats[2]!.defaultKey, 'transport');
      expect(cats[11]!.defaultKey, 'otherIncome');
    });

    test('A row with the right name but the wrong type is not tagged', () async {
      final db = openV5(extra: ['UPDATE categories SET type = 1 WHERE id = 3']);
      addTearDown(db.close);
      expect((await load(db))[3]!.defaultKey, isNull);
    });

    test('Deleting a built-in category earlier does not shift the others', () async {
      final db = openV5(extra: ['DELETE FROM categories WHERE id = 4']);
      addTearDown(db.close);
      final cats = await load(db);

      expect(cats.containsKey(4), isFalse);
      expect(cats[3]!.defaultKey, 'shopping');
      expect(cats[5]!.defaultKey, 'housing'); // still matched by its own id
      expect(cats.values.where((c) => c.defaultKey != null).length, 10);
    });

    test('Icons and colors the user set are kept', () async {
      final db = openV5(extra: [
        "UPDATE categories SET icon = 'flight', color = 5 WHERE id = 1",
      ]);
      addTearDown(db.close);
      final c = (await load(db))[1]!;
      expect(c.icon, 'flight');
      expect(c.color, 5);
      expect(c.defaultKey, 'food');
    });
  });

  test('A fresh database starts with the built-in categories, already tagged', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final cats = await (db.select(db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.id)]))
        .get();

    expect(cats.map((c) => c.id), List.generate(11, (i) => i + 1));
    expect(cats.map((c) => c.defaultKey), defaultCategories.map((c) => c.key));
    expect(cats.map((c) => c.type), defaultCategories.map((c) => c.type));
  });
}
