import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ledger'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
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