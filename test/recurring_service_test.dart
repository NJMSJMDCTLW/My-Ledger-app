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

  test('Fills in every due month after the start date', () async {
    await addRule(day: 5, start: DateTime(2026, 8, 20));
    // Starting 8/20: 8/5 is before the start and does not count; 9/5 and 10/5 are due; 11/5 is not yet
    final n = await generateDueTransactions(db, now: DateTime(2026, 10, 26));
    expect(n, 2);
    expect(await generatedDates(), [DateTime(2026, 9, 5), DateTime(2026, 10, 5)]);
  });

  test('Running again does not create duplicates', () async {
    await addRule(day: 5, start: DateTime(2026, 9, 1));
    final now = DateTime(2026, 10, 26);
    expect(await generateDueTransactions(db, now: now), 2);
    expect(await generateDueTransactions(db, now: now), 0);
    expect((await generatedDates()).length, 2);
  });

  test('Opening the app after several months fills in the missed ones', () async {
    await addRule(day: 5, start: DateTime(2026, 9, 1));
    await generateDueTransactions(db, now: DateTime(2026, 10, 26));
    final n = await generateDueTransactions(db, now: DateTime(2027, 1, 10));
    expect(n, 3); // 11/5、12/5、1/5
  });

  test('Day 31 falls back to the last day in shorter months', () async {
    await addRule(day: 31, start: DateTime(2026, 1, 1));
    await generateDueTransactions(db, now: DateTime(2026, 3, 31));
    expect(await generatedDates(), [
      DateTime(2026, 1, 31),
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
    ]);
  });

  test('Generated on the exact due day, not before', () async {
    await addRule(day: 26, start: DateTime(2026, 10, 1));
    expect(await generateDueTransactions(db, now: DateTime(2026, 10, 25)), 0);
    expect(await generateDueTransactions(db, now: DateTime(2026, 10, 26)), 1);
  });

  test('A paused rule generates nothing', () async {
    await addRule(day: 5, start: DateTime(2026, 9, 1), active: false);
    expect(await generateDueTransactions(db, now: DateTime(2026, 10, 26)), 0);
  });
}
