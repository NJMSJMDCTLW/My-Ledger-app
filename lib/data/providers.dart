import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final accountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.accounts)..where((a) => a.isArchived.equals(false)))
      .watch();
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
  for (final t in txs) {
    switch (t.type) {
      case TransactionType.expense:
        balances[t.accountId] = (balances[t.accountId] ?? 0) - t.amount;
      case TransactionType.income:
        balances[t.accountId] = (balances[t.accountId] ?? 0) + t.amount;
      case TransactionType.transfer:
        balances[t.accountId] = (balances[t.accountId] ?? 0) - t.amount;
        final to = t.toAccountId;
        if (to != null) {
          balances[to] = (balances[to] ?? 0) + t.amount;
        }
    }
  }
  return balances;
});
