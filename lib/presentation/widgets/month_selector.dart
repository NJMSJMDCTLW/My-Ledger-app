import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/data/providers.dart';

/// The month switcher row, e.g. "< October 2026 >".
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
          tooltip: context.l10n.tooltipPreviousMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => notifier.shift(-1),
        ),
        Text(
          context.l10n.monthTitle(month),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          tooltip: context.l10n.tooltipNextMonth,
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrentMonth ? null : () => notifier.shift(1),
        ),
      ],
    );
  }
}
