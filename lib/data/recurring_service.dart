import 'package:drift/drift.dart';
import 'package:hello_ledger/core/billing_dates.dart';
import 'package:hello_ledger/data/app_database.dart';

/// For each active recurring rule, creates the transactions that are "due but not yet generated".
///
/// Rule: starting from the month of the start date, on day dayOfMonth of each month (or the last day if the month lacks it),
/// a transaction is created if the date is >= the start date, <= today, and newer than lastGenerated.
/// After a long time without opening the app, all missed months are filled in at once. Running it again never creates duplicates.
///
/// Returns how many transactions were newly created this time.
Future<int> generateDueTransactions(AppDatabase db, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);

  return db.transaction(() async {
    final rules = await (db.select(db.recurringRules)
          ..where((r) => r.isActive.equals(true)))
        .get();

    var created = 0;
    for (final rule in rules) {
      final start = DateTime(
          rule.startDate.year, rule.startDate.month, rule.startDate.day);
      DateTime? last = rule.lastGenerated;

      var month = DateTime(start.year, start.month);
      while (!month.isAfter(today)) {
        final due = dayInMonth(month.year, month.month, rule.dayOfMonth);
        final isNew = last == null || due.isAfter(last);
        if (!due.isBefore(start) && !due.isAfter(today) && isNew) {
          await db.into(db.transactions).insert(
                TransactionsCompanion.insert(
                  date: due,
                  amount: rule.amount,
                  type: rule.type,
                  accountId: rule.accountId,
                  toAccountId: Value(rule.toAccountId),
                  categoryId: Value(rule.categoryId),
                  note: Value(rule.note),
                ),
              );
          last = due;
          created++;
        }
        month = DateTime(month.year, month.month + 1);
      }

      if (last != rule.lastGenerated) {
        await (db.update(db.recurringRules)..where((r) => r.id.equals(rule.id)))
            .write(RecurringRulesCompanion(lastGenerated: Value(last)));
      }
    }
    return created;
  });
}
