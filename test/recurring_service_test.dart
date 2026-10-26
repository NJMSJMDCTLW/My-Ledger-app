import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/recurring_service.dart';

void main() {
  late AppDatabase db;
  late int accountId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    accountId = await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: '現金', type: AccountType.cash));
  });

  tearDown(() => db.close());

  Future<int> addRule({
    required int day,
    required DateTime start,
    bool active = true,
  }) {
    return db.into(db.recurringRules).insert(
          RecurringRulesCompanion.insert(
            type: TransactionType.expense,
            amount: 100000,
            accountId: accountId,
            dayOfMonth: day,
            startDate: start,
            isActive: Value(active),
          ),
        );
  }

  Future<List<DateTime>> generatedDates() async {
    final rows = await (db.select(db.transactions)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
    return rows.map((t) => t.date).toList();
  }

  test('補上開始日期之後所有已到期的月份', () async {
    await addRule(day: 5, start: DateTime(2026, 8, 20));
    // 8/20 開始 -> 8/5 在開始之前不算；9/5、10/5 已到期；11/5 還沒到
    final n = await generateDueTransactions(db, now: DateTime(2026, 10, 26));
    expect(n, 2);
    expect(await generatedDates(), [DateTime(2026, 9, 5), DateTime(2026, 10, 5)]);
  });

  test('重複執行不會重複產生', () async {
    await addRule(day: 5, start: DateTime(2026, 9, 1));
    final now = DateTime(2026, 10, 26);
    expect(await generateDueTransactions(db, now: now), 2);
    expect(await generateDueTransactions(db, now: now), 0);
    expect((await generatedDates()).length, 2);
  });

  test('隔了幾個月再開 App 會補上漏掉的', () async {
    await addRule(day: 5, start: DateTime(2026, 9, 1));
    await generateDueTransactions(db, now: DateTime(2026, 10, 26));
    final n = await generateDueTransactions(db, now: DateTime(2027, 1, 10));
    expect(n, 3); // 11/5、12/5、1/5
  });

  test('31 號遇到小月改在月底', () async {
    await addRule(day: 31, start: DateTime(2026, 1, 1));
    await generateDueTransactions(db, now: DateTime(2026, 3, 31));
    expect(await generatedDates(), [
      DateTime(2026, 1, 31),
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
    ]);
  });

  test('當天剛好到期就會產生，還沒到就不會', () async {
    await addRule(day: 26, start: DateTime(2026, 10, 1));
    expect(await generateDueTransactions(db, now: DateTime(2026, 10, 25)), 0);
    expect(await generateDueTransactions(db, now: DateTime(2026, 10, 26)), 1);
  });

  test('暫停中的規則不產生', () async {
    await addRule(day: 5, start: DateTime(2026, 9, 1), active: false);
    expect(await generateDueTransactions(db, now: DateTime(2026, 10, 26)), 0);
  });
}
