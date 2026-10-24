import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/notification_service.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 所有帳戶（含已封存），用來顯示歷史交易的帳戶名稱。
final allAccountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.accounts).watch();
});

/// 目前選定的月份（首頁與統計分頁共用）。
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void shift(int months) {
    state = DateTime(state.year, state.month + months);
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);

/// 選定月份的統計。
class MonthlyStats {
  const MonthlyStats({
    required this.txs,
    required this.income,
    required this.expense,
    required this.categoryRows,
  });

  /// 這個月的所有交易（含轉帳），新的在前面。
  final List<TransactionRecord> txs;
  final int income;
  final int expense;

  /// 支出類別（類別 id，金額），金額大的在前面。
  final List<MapEntry<int?, int>> categoryRows;

  int get balance => income - expense;
}

final monthlyStatsProvider = Provider<MonthlyStats>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  final txs = all
      .where((t) => t.date.year == month.year && t.date.month == month.month)
      .toList();

  var income = 0;
  var expense = 0;
  final byCategory = <int?, int>{};
  for (final t in txs) {
    if (t.type == TransactionType.income) {
      income += t.amount;
    } else if (t.type == TransactionType.expense) {
      expense += t.amount;
      byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
    }
  }
  final rows = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return MonthlyStats(
    txs: txs,
    income: income,
    expense: expense,
    categoryRows: rows,
  );
});

/// 帳戶一有變動就重新排程信用卡繳款提醒。在 App 最上層 watch 它即可。
final reminderSyncProvider = Provider<void>((ref) {
  final accounts = ref.watch(allAccountsProvider).value;
  if (accounts == null) return;
  NotificationService.instance.rescheduleCreditCardReminders(accounts);
});

/// 使用中的帳戶（未封存）。
final accountsProvider = Provider<AsyncValue<List<Account>>>((ref) {
  return ref
      .watch(allAccountsProvider)
      .whenData((list) => list.where((a) => !a.isArchived).toList());
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.categories).watch();
});

/// 所有交易，新的在前面。
final transactionsProvider = StreamProvider<List<TransactionRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..orderBy([
          (t) => OrderingTerm.desc(t.date),
          (t) => OrderingTerm.desc(t.id),
        ]))
      .watch();
});

/// 每個帳戶目前的餘額（單位：分），key 是帳戶 id。
final balancesProvider = Provider<Map<int, int>>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  final txs = ref.watch(transactionsProvider).value ?? [];

  final balances = {for (final a in accounts) a.id: a.openingBalance};
  // 已封存帳戶不在 balances 裡，它的交易就不計入
  void add(int? id, int delta) {
    if (id != null && balances.containsKey(id)) {
      balances[id] = balances[id]! + delta;
    }
  }

  for (final t in txs) {
    switch (t.type) {
      case TransactionType.expense:
        add(t.accountId, -t.amount);
      case TransactionType.income:
        add(t.accountId, t.amount);
      case TransactionType.transfer:
        add(t.accountId, -t.amount);
        add(t.toAccountId, t.amount);
    }
  }
  return balances;
});
