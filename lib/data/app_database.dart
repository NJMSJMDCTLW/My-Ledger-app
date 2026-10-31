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
  int get schemaVersion => 5;

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