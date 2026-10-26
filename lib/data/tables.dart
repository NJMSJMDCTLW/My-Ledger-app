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

  /// 轉帳時轉入帳戶實際收到的金額（單位：分，用轉入帳戶的貨幣）。
  /// 兩個帳戶貨幣不同時才會有值；null 代表和 amount 一樣。
  IntColumn get toAmount => integer().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 固定收支的規則（例如每月 5 號的房租）。
/// App 啟動時，會替每條規則補上已到期但還沒產生的交易。
@DataClassName('RecurringRule')
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<TransactionType>()();

  /// 金額一律存正整數，單位是「分」。
  IntColumn get amount => integer()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// 每月幾號（1~31）。該月沒有這一天就用月底。
  IntColumn get dayOfMonth => integer()();

  /// 從這天起才開始產生交易。
  DateTimeColumn get startDate => dateTime()();

  /// 最近一次已產生的交易日期，避免重複產生。
  DateTimeColumn get lastGenerated => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}


/// 匯率：1 單位外幣等於多少港幣。港幣本身固定是 1，不存在這張表裡。
/// 匯率由使用者手動設定，用來把外幣帳戶折合成港幣。
@DataClassName('ExchangeRate')
class ExchangeRates extends Table {
  /// 貨幣代碼，例如 USD、JPY。
  TextColumn get currency => text()();
  RealColumn get rateToHkd => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {currency};
}
