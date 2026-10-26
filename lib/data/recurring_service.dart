import 'package:drift/drift.dart';
import 'package:hello_ledger/core/billing_dates.dart';
import 'package:hello_ledger/data/app_database.dart';

/// 替每條啟用中的固定收支規則，補上「已到期但還沒產生」的交易。
///
/// 規則：從開始日期那個月起，每個月的 dayOfMonth 號（沒有那天就用月底）
/// 只要 >= 開始日期、<= 今天、且比 lastGenerated 新，就產生一筆。
/// 很久沒開 App 時會一次補上所有漏掉的月份。重複執行不會重複產生。
///
/// 回傳這次新產生了幾筆交易。
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
