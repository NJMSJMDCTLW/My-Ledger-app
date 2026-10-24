import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:intl/intl.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(transactionsProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];
    final categoryNames = {for (final c in categories) c.id: c.name};

    // 只看選定月份，轉帳不算收入也不算支出
    final inMonth = txs.where((t) =>
        t.date.year == _month.year &&
        t.date.month == _month.month &&
        t.type != TransactionType.transfer);

    var income = 0;
    var expense = 0;
    final byCategory = <int?, int>{};
    for (final t in inMonth) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
        byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
      }
    }
    final rows = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('每月統計')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: '上個月',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Text(
                DateFormat('yyyy 年 M 月').format(_month),
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                tooltip: '下個月',
                icon: const Icon(Icons.chevron_right),
                onPressed: isCurrentMonth ? null : () => _shift(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Summary(label: '收入', cents: income, color: Colors.green),
              _Summary(label: '支出', cents: expense, color: Colors.red),
              _Summary(label: '結餘', cents: income - expense),
            ],
          ),
          const SizedBox(height: 24),
          Text('支出類別', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('這個月沒有支出')),
            )
          else
            for (final r in rows)
              _CategoryRow(
                name: categoryNames[r.key] ?? '未分類',
                cents: r.value,
                ratio: expense == 0 ? 0 : r.value / expense,
              ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.cents, this.color});

  final String label;
  final int cents;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCents(cents),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.cents,
    required this.ratio,
  });

  final String name;
  final int cents;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$name  ${(ratio * 100).toStringAsFixed(1)}%'),
              Text(formatCents(cents)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: ratio, minHeight: 8),
        ],
      ),
    );
  }
}
