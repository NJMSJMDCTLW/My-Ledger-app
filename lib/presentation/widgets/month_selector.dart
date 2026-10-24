import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:intl/intl.dart';

/// 「< 2026 年 10 月 >」月份切換列。
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final notifier = ref.read(selectedMonthProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: '上個月',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => notifier.shift(-1),
        ),
        Text(
          DateFormat('yyyy 年 M 月').format(month),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          tooltip: '下個月',
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrentMonth ? null : () => notifier.shift(1),
        ),
      ],
    );
  }
}
