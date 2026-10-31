import 'dart:ui' show PlatformDispatcher;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/core/notification_service.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/hkd_converter.dart';
import 'package:hello_ledger/data/rate_service.dart';
import 'package:hello_ledger/data/recurring_service.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/data/stats_range.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// All accounts (including archived ones), used to show account names on historical transactions.
final allAccountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.accounts).watch();
});

/// The currently selected month (shared by the home and statistics tabs).
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Moves forward or back by some months; it cannot go past the current month (there are no future records to view).
  void shift(int months) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final target = DateTime(state.year, state.month + months);
    state = target.isAfter(thisMonth) ? thisMonth : target;
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);

/// Statistics for the selected month.
class MonthlyStats {
  const MonthlyStats({
    required this.txs,
    required this.income,
    required this.expense,
    required this.categoryRows,
  });

  /// All transactions in this month (including transfers), newest first.
  final List<TransactionRecord> txs;
  final int income;
  final int expense;

  /// Expense categories as (category id, amount), largest amount first.
  final List<MapEntry<int?, int>> categoryRows;

  int get balance => income - expense;
}

final monthlyStatsProvider = Provider<MonthlyStats>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  return computeMonthlyStats(all, month,
      converter: ref.watch(hkdConverterProvider));
});

/// The kind of time range selected on the statistics tab (monthly, last six months, or one year).
class SelectedStatsPeriod extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() => StatsPeriod.month;

  void select(StatsPeriod period) => state = period;
}

final statsPeriodProvider =
    NotifierProvider<SelectedStatsPeriod, StatsPeriod>(SelectedStatsPeriod.new);

/// The current time range on the statistics tab: derived from the kind plus the shared month.
final statsRangeProvider = Provider<StatsRange>((ref) {
  return statsRangeFor(
    ref.watch(statsPeriodProvider),
    ref.watch(selectedMonthProvider),
  );
});

/// Statistics for the range on the statistics tab.
final periodStatsProvider = Provider<MonthlyStats>((ref) {
  final range = ref.watch(statsRangeProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  return computeRangeStats(all, range.start, range.end,
      converter: ref.watch(hkdConverterProvider));
});

/// Statistics for the "previous period" (last month, the previous six months, or last year), used for comparison.
final previousPeriodStatsProvider = Provider<MonthlyStats>((ref) {
  final range = ref.watch(statsRangeProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  return computeRangeStats(all, range.previousStart, range.previousEnd,
      converter: ref.watch(hkdConverterProvider));
});

/// Income and expense for each month in the range, used to draw the bar chart.
final periodMonthlyTotalsProvider = Provider<List<MonthTotals>>((ref) {
  final range = ref.watch(statsRangeProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  return monthlyTotals(all, range, converter: ref.watch(hkdConverterProvider));
});

/// Computes the statistics for one month.
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

/// Computes statistics from [start] (inclusive) to [end] (exclusive).
/// With a [converter], each amount is converted to HKD before summing; without one, the original amounts are used.
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

/// Whenever the recurring rules change (including right after the app starts), creates any due transactions.
/// Creating transactions updates lastGenerated, so the rules stream emits again, but the second pass creates nothing new, so there is no infinite loop.
final recurringSyncProvider = Provider<void>((ref) {
  final rules = ref.watch(recurringRulesProvider).value;
  if (rules == null) return;
  generateDueTransactions(ref.read(databaseProvider));
});

/// Reschedules the credit card due-date reminders whenever accounts change. Just watch it at the top of the app.
final reminderSyncProvider = Provider<void>((ref) {
  // The reminder text is fixed when it is scheduled, so a language change reschedules them too
  final language = ref.watch(appLanguageProvider);
  final accounts = ref.watch(allAccountsProvider).value;
  if (accounts == null) return;
  NotificationService.instance.rescheduleCreditCardReminders(
    accounts,
    localizationsFor(language, PlatformDispatcher.instance.locales),
  );
});

/// Active (non-archived) accounts.
final accountsProvider = Provider<AsyncValue<List<Account>>>((ref) {
  return ref
      .watch(allAccountsProvider)
      .whenData((list) => list.where((a) => !a.isArchived).toList());
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.categories).watch();
});

/// All transactions, newest first.
final transactionsProvider = StreamProvider<List<TransactionRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..orderBy([
          (t) => OrderingTerm.desc(t.date),
          (t) => OrderingTerm.desc(t.id),
        ]))
      .watch();
});

/// Each account's current balance (in cents, in that account's own currency), keyed by account id.
/// Archived accounts are not included, so their transactions are not counted.
final balancesProvider = Provider<Map<int, int>>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  final txs = ref.watch(transactionsProvider).value ?? [];
  return computeBalances(accounts, txs);
});

/// Exchange rates (foreign currency -> HKD), set by the user manually or updated automatically.
final exchangeRatesProvider = StreamProvider<List<ExchangeRate>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.exchangeRates).watch();
});

/// A converter that turns each currency into HKD; it updates whenever accounts or rates change.
final hkdConverterProvider = Provider<HkdConverter>((ref) {
  return HkdConverter.from(
    accounts: ref.watch(allAccountsProvider).value ?? [],
    rates: ref.watch(exchangeRatesProvider).value ?? [],
  );
});

/// Total balance (in HKD cents): the balances of all active accounts converted to HKD and summed.
final totalAssetsHkdProvider = Provider<int>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  final balances = ref.watch(balancesProvider);
  final converter = ref.watch(hkdConverterProvider);
  return accounts.fold<int>(
    0,
    (sum, a) => sum + converter.toHkd(balances[a.id] ?? 0, a.currency),
  );
});

/// Foreign currencies used by active accounts that have no rate set yet. If any exist, the HKD amounts are incomplete.
final missingRateCurrenciesProvider = Provider<Set<String>>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  final converter = ref.watch(hkdConverterProvider);
  return {
    for (final a in accounts)
      if (!converter.hasRate(a.currency)) a.currency,
  };
});

/// State of the automatic exchange-rate update, used by the rates tab to show "updating", "last updated", and the failure reason.
class RateUpdateState {
  const RateUpdateState({
    this.isLoading = false,
    this.error,
    this.lastSuccess,
  });

  final bool isLoading;

  /// Why the last update failed; null if it succeeded or has not run yet.
  final RateFetchError? error;

  /// When the most recent successful update happened during this app session.
  final DateTime? lastSuccess;
}

class RateUpdater extends Notifier<RateUpdateState> {
  @override
  RateUpdateState build() => const RateUpdateState();

  /// Fetches the latest rates and updates them. Returns true on success; returns false on failure (e.g. offline), with the reason in state.error.
  Future<bool> refresh() async {
    if (state.isLoading) return false;
    state = RateUpdateState(isLoading: true, lastSuccess: state.lastSuccess);
    try {
      await updateExchangeRates(ref.read(databaseProvider));
      state = RateUpdateState(lastSuccess: DateTime.now());
      return true;
    } on RateFetchException catch (e) {
      state = RateUpdateState(error: e.error, lastSuccess: state.lastSuccess);
      return false;
    } catch (_) {
      state = RateUpdateState(
        error: RateFetchError.unknown,
        lastSuccess: state.lastSuccess,
      );
      return false;
    }
  }
}

final rateUpdaterProvider =
    NotifierProvider<RateUpdater, RateUpdateState>(RateUpdater.new);

/// When the app opens (and when accounts change), updates the exchange rates automatically if needed. Just watch it at the top of the app.
/// Failures such as being offline are skipped silently without bothering the user; the reason stays in [rateUpdaterProvider].
final rateStartupSyncProvider = FutureProvider<void>((ref) async {
  final accounts = (await ref.watch(allAccountsProvider.future))
      .where((a) => !a.isArchived)
      .toList();
  final rates = await ref.watch(exchangeRatesProvider.future);

  final needed = shouldAutoUpdate(
    rates: rates,
    currenciesInUse: {for (final a in accounts) a.currency},
    now: DateTime.now(),
  );
  if (needed) await ref.read(rateUpdaterProvider.notifier).refresh();
});
