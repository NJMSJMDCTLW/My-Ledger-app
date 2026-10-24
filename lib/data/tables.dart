import 'package:drift/drift.dart';
import 'package:hello_ledger/data/enums.dart';

@DataClassName('Account')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get type => intEnum<AccountType>()();
  TextColumn get currency => text().withDefault(const Constant('HKD'))();

  /// 期初餘額，單位是「分」。信用卡的欠款用負數表示。
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  // 以下只有信用卡才會用到
  IntColumn get creditLimit => integer().nullable()();
  IntColumn get statementDay => integer().nullable()();
  IntColumn get dueDay => integer().nullable()();
  TextColumn get last4 => text().withLength(min: 4, max: 4).nullable()();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  IntColumn get type => intEnum<CategoryType>()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
}

@DataClassName('TransactionRecord')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();

  /// 金額一律存正整數，單位是「分」。收入或支出由 type 決定。
  IntColumn get amount => integer()();
  IntColumn get type => intEnum<TransactionType>()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}