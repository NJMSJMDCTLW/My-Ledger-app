import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/notification_service.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/hkd_converter.dart';
import 'package:hello_ledger/data/recurring_service.dart';
import 'package:hello_ledger/data/stats_range.dart';

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

  /// 前後移動幾個月；不能超過這個月（沒有未來的紀錄可看）。
  void shift(int months) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final target = DateTime(state.year, state.month + months);
    state = target.isAfter(thisMonth) ? thisMonth : target;
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
  return computeMonthlyStats(all, month,
      converter: ref.watch(hkdConverterProvider));
});

/// 統計分頁目前選的時間範圍種類（每月、近六個月、一年）。
class SelectedStatsPeriod extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() => StatsPeriod.month;

  void select(StatsPeriod period) => state = period;
}

final statsPeriodProvider =
    NotifierProvider<SelectedStatsPeriod, StatsPeriod>(SelectedStatsPeriod.new);

/// 統計分頁目前的時間範圍：由種類加上共用的月份算出來。
final statsRangeProvider = Provider<StatsRange>((ref) {
  return statsRangeFor(
    ref.watch(statsPeriodProvider),
    ref.watch(selectedMonthProvider),
  );
});

/// 統計分頁範圍內的統計。
final periodStatsProvider = Provider<MonthlyStats>((ref) {
  final range = ref.watch(statsRangeProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  return computeRangeStats(all, range.start, range.end,
      converter: ref.watch(hkdConverterProvider));
});

/// 「上一期」的統計（上個月、前六個月、去年），用來做比較。
final previousPeriodStatsProvider = Provider<MonthlyStats>((ref) {
  final range = ref.watch(statsRangeProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  return computeRangeStats(all, range.previousStart, range.previousEnd,
      converter: ref.watch(hkdConverterProvider));
});

/// 範圍內每個月的收入與支出，畫長條圖用。
final periodMonthlyTotalsProvider = Provider<List<MonthTotals>>((ref) {
  final range = ref.watch(statsRangeProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  return monthlyTotals(all, range, converter: ref.watch(hkdConverterProvider));
});

/// 算出某個月份的統計。
MonthlyStats computeMonthlyStats(
  List<TransactionRecord> all,
  DateTime month, {
  HkdConverter? converter,
}) {
  return computeRangeStats(
    all,
    DateTime(month.year, month.month),
    DateTime(month.year, month.month + 1),
    converter: converter,
  );
}

/// 算出 [start]（含）到 [end]（不含）之間的統計。
/// 給了 [converter] 就把每筆金額折成港幣再加總；沒給就直接用原本的金額。
MonthlyStats computeRangeStats(
  List<TransactionRecord> all,
  DateTime start,
  DateTime end, {
  HkdConverter? converter,
}) {
  final txs =
      all.where((t) => !t.date.isBefore(start) && t.date.isBefore(end)).toList();

  var income = 0;
  var expense = 0;
  final byCategory = <int?, int>{};
  for (final t in txs) {
    final amount = converter?.amountOf(t) ?? t.amount;
    if (t.type == TransactionType.income) {
      income += amount;
    } else if (t.type == TransactionType.expense) {
      expense += amount;
      byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + amount;
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
}

final recurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.recurringRules)
        ..orderBy([(r) => OrderingTerm.asc(r.dayOfMonth)]))
      .watch();
});

/// 固定收支規則一有變動（包含 App 剛啟動），就補上到期的交易。
/// 產生交易後 lastGenerated 會更新，規則串流再發一次，但第二次不會再產生新的，所以不會無限循環。
final recurringSyncProvider = Provider<void>((ref) {
  final rules = ref.watch(recurringRulesProvider).value;
  if (rules == null) return;
  generateDueTransactions(ref.read(databaseProvider));
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

/// 每個帳戶目前的餘額（單位：分，用該帳戶自己的貨幣），key 是帳戶 id。
/// 已封存帳戶不在裡面，它的交易就不計入。
final balancesProvider = Provider<Map<int, int>>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  final txs = ref.watch(transactionsProvider).value ?? [];
  return computeBalances(accounts, txs);
});

/// 匯率（外幣 -> 港幣），由使用者手動設定。
final exchangeRatesProvider = StreamProvider<List<ExchangeRate>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.exchangeRates).watch();
});

/// 把各貨幣折成港幣的換算器，帳戶或匯率一變就會更新。
final hkdConverterProvider = Provider<HkdConverter>((ref) {
  return HkdConverter.from(
    accounts: ref.watch(allAccountsProvider).value ?? [],
    rates: ref.watch(exchangeRatesProvider).value ?? [],
  );
});

/// 總資產（港幣，單位：分）：所有使用中帳戶的餘額折成港幣後加總。
final totalAssetsHkdProvider = Provider<int>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  final balances = ref.watch(balancesProvider);
  final converter = ref.watch(hkdConverterProvider);
  return accounts.fold<int>(
    0,
    (sum, a) => sum + converter.toHkd(balances[a.id] ?? 0, a.currency),
  );
});

/// 使用中的帳戶裡，用到但還沒設定匯率的外幣。有的話折合的港幣金額就不完整。
final missingRateCurrenciesProvider = Provider<Set<String>>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  final converter = ref.watch(hkdConverterProvider);
  return {
    for (final a in accounts)
      if (!converter.hasRate(a.currency)) a.currency,
  };
});
