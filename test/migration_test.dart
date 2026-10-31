import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

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
}
