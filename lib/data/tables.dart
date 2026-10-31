import 'package:drift/drift.dart';
import 'package:hello_ledger/data/enums.dart';

@DataClassName('Account')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get type => intEnum<AccountType>()();
  TextColumn get currency => text().withDefault(const Constant('HKD'))();

  /// Opening balance, in cents. A credit card's debt is stored as a negative number.
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  // The fields below are only used by credit cards
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

  /// Set only for the built-in categories (see default_categories.dart). Their name is shown
  /// translated, so [name] is just a fallback. Renaming one clears this and keeps the new name.
  TextColumn get defaultKey => text().nullable()();
}

@DataClassName('TransactionRecord')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();

  /// Amounts are always stored as positive integers, in cents. Whether it is income or expense is decided by type.
  IntColumn get amount => integer()();
  IntColumn get type => intEnum<TransactionType>()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();

  /// For a transfer, the amount the destination account actually receives (in cents, in the destination account's currency).
  /// Only set when the two accounts have different currencies; null means the same as amount.
  IntColumn get toAmount => integer().nullable()();

  /// When the currency the user entered differs from the account's currency, keeps the original value they entered (in cents).
  /// [amount] is the amount converted to the account's currency at the rate of that time and never changes again with the rate.
  /// The two columns are either both set or both null.
  IntColumn get originalAmount => integer().nullable()();
  TextColumn get originalCurrency => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A recurring rule (for example, rent on the 5th of every month).
/// When the app starts, each rule gets any due-but-not-yet-generated transactions created.
@DataClassName('RecurringRule')
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<TransactionType>()();

  /// Amounts are always stored as positive integers, in cents.
  IntColumn get amount => integer()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Day of the month (1-31). If the month lacks that day, the last day of the month is used.
  IntColumn get dayOfMonth => integer()();

  /// Transactions are only generated from this date on.
  DateTimeColumn get startDate => dateTime()();

  /// The date of the most recently generated transaction, to avoid generating duplicates.
  DateTimeColumn get lastGenerated => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}


/// Exchange rate: how many HKD one unit of a foreign currency is worth. HKD itself is always 1 and is not stored in this table.
/// Rates are either set by the user or updated automatically, and are used to convert foreign-currency accounts to HKD.
@DataClassName('ExchangeRate')
class ExchangeRates extends Table {
  /// Currency code, e.g. USD, JPY.
  TextColumn get currency => text()();
  RealColumn get rateToHkd => real()();

  /// True means the user entered this rate by hand, so automatic updates never overwrite it.
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {currency};
}
