import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
        },
        onUpgrade: (m, from, to) async {
          // v1 -> v2：新增固定收支的資料表，原本的資料不動
          if (from < 2) await m.createTable(recurringRules);
          // v2 -> v3：多貨幣。新增匯率表，以及轉帳的「轉入金額」欄位
          if (from < 3) {
            // 這張表是照最新的樣子建的，已經包含 v4 的 isManual 欄位
            await m.createTable(exchangeRates);
            await m.addColumn(transactions, transactions.toAmount);
          }
          // v3 -> v4：匯率可以自動更新。v3 的匯率都是使用者自己填的，標成手動，
          // 這樣第一次自動更新時不會把它們蓋掉
          if (from == 3) {
            await m.addColumn(exchangeRates, exchangeRates.isManual);
            await customStatement('UPDATE exchange_rates SET is_manual = 1');
          }
        },
      );

  Future<void> _seedCategories() async {
    const expense = [
      '餐飲', '交通', '購物', '娛樂', '居住', '醫療', '教育', '其他',
    ];
    const income = ['薪水', '獎金', '其他'];

    await batch((b) {
      b.insertAll(categories, [
        for (final name in expense)
          CategoriesCompanion.insert(name: name, type: CategoryType.expense),
        for (final name in income)
          CategoriesCompanion.insert(name: name, type: CategoryType.income),
      ]);
    });
  }
}