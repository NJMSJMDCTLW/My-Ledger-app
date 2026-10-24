import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
