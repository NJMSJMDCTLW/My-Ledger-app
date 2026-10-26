import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

void main() {
  test('從第 2 版升級到第 3 版：舊資料保留，新欄位與匯率表可以用', () async {
    // 手動建出第 2 版的資料庫（transactions 還沒有 to_amount，也沒有 exchange_rates）
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

    // 舊資料還在，新欄位是 null
    final accounts = await db.select(db.accounts).get();
    expect(accounts.single.name, '現金');
    expect(accounts.single.currency, 'HKD');
    expect(accounts.single.openingBalance, 5000);

    final txs = await db.select(db.transactions).get();
    expect(txs.single.amount, 1234);
    expect(txs.single.note, '午餐');
    expect(txs.single.toAmount, isNull);

    // 新的匯率表可以用
    await db.into(db.exchangeRates).insert(
          ExchangeRatesCompanion.insert(currency: 'USD', rateToHkd: 7.8),
        );
    final rates = await db.select(db.exchangeRates).get();
    expect(rates.single.currency, 'USD');
    expect(rates.single.rateToHkd, 7.8);

    // 新欄位可以寫入
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            date: DateTime(2026, 10, 1),
            amount: 78000,
            type: TransactionType.transfer,
            accountId: 1,
          ),
        );
  });

  test('從第 3 版升級到第 4 版：原本的匯率保留，並標成手動', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // 第 3 版的匯率表：還沒有 is_manual 欄位
          raw.execute('''
            CREATE TABLE exchange_rates (
              currency TEXT NOT NULL PRIMARY KEY,
              rate_to_hkd REAL NOT NULL,
              updated_at INTEGER NOT NULL DEFAULT 0
            );
          ''');
          raw.execute(
              "INSERT INTO exchange_rates (currency, rate_to_hkd, updated_at) VALUES ('USD', 7.8, 1790000000)");
          // 真實的第 3 版資料庫一定有交易表（已經有 to_amount），升級時會繼續往上加欄位
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
    // 使用者自己填過的匯率，升級後要視為手動，第一次自動更新才不會蓋掉
    expect(rates.single.isManual, isTrue);
  });

  test('從第 4 版升級到第 5 版：舊交易保留，原始金額與貨幣是 null', () async {
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
