import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, Transactions, RecurringRules])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'ledger'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
        },
        onUpgrade: (m, from, to) async {
          // v1 -> v2：新增固定收支的資料表，原本的資料不動
          if (from < 2) await m.createTable(recurringRules);
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