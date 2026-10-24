import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/account_form_page.dart';
import 'package:hello_ledger/presentation/transaction_form_page.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final txs = ref.watch(transactionsProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];
    final balances = ref.watch(balancesProvider);

    final total = balances.values.fold<int>(0, (sum, v) => sum + v);
    final accountNames = {for (final a in accounts) a.id: a.name};
    final categoryNames = {for (final c in categories) c.id: c.name};

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的記帳本'),
        actions: [
          IconButton(
            tooltip: '新增帳戶',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => _open(context, const AccountFormPage()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, const TransactionFormPage()),
        icon: const Icon(Icons.add),
        label: const Text('記一筆'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('總資產'),
                Text(
                  formatCents(total),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
          const _SectionTitle('帳戶'),
          if (accounts.isEmpty)
            const ListTile(title: Text('還沒有帳戶，點右上角新增'))
          else
            for (final a in accounts)
              ListTile(
                title: Text(a.name),
                subtitle: Text(a.type.label),
                trailing: Text(formatCents(balances[a.id] ?? 0)),
              ),
          const _SectionTitle('最近交易'),
          if (txs.isEmpty)
            const ListTile(title: Text('還沒有交易'))
          else
            for (final t in txs.take(50))
              ListTile(
                onTap: () => _open(context, TransactionFormPage(existing: t)),
                title: Text(t.type == TransactionType.transfer
                    ? '轉帳：${accountNames[t.accountId] ?? '?'} → ${accountNames[t.toAccountId] ?? '?'}'
                    : categoryNames[t.categoryId] ?? '未分類'),
                subtitle: Text([
                  DateFormat('yyyy/MM/dd').format(t.date),
                  if (t.type != TransactionType.transfer)
                    accountNames[t.accountId] ?? '?',
                  if (t.note.isNotEmpty) t.note,
                ].join(' · ')),
                trailing: Text(
                  switch (t.type) {
                    TransactionType.expense => '-${formatCents(t.amount)}',
                    TransactionType.income => '+${formatCents(t.amount)}',
                    TransactionType.transfer => formatCents(t.amount),
                  },
                  style: TextStyle(
                    color: switch (t.type) {
                      TransactionType.expense => Colors.red,
                      TransactionType.income => Colors.green,
                      TransactionType.transfer => null,
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
