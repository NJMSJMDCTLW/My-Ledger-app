import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/stats_range.dart';

/// The top of the statistics tab: switches between monthly / last six months / one year, plus the arrows that move back and forward.
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  static String _ym(DateTime d) => '${d.year}/${d.month}';

  /// The title text for the current range.
  static String title(StatsPeriod period, StatsRange range) {
    final last = DateTime(range.end.year, range.end.month - 1);
    return switch (period) {
      StatsPeriod.month => '${range.start.year} 年 ${range.start.month} 月',
      StatsPeriod.sixMonths => '${_ym(range.start)} – ${_ym(last)}',
      StatsPeriod.year => '${range.start.year} 年',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final range = ref.watch(statsRangeProvider);
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    // Already at the latest period, so it cannot go forward: the last month of the range is >= this month
    final lastMonthInRange = DateTime(range.end.year, range.end.month - 1);
    final canGoNext = switch (period) {
      StatsPeriod.year => range.start.year < thisMonth.year,
      _ => lastMonthInRange.isBefore(thisMonth),
    };

    final notifier = ref.read(selectedMonthProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<StatsPeriod>(
            segments: [
              for (final p in StatsPeriod.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {period},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(statsPeriodProvider.notifier).select(s.first),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: '往前',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => notifier.shift(-period.stepMonths),
            ),
            Text(
              title(period, range),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              tooltip: '往後',
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  canGoNext ? () => notifier.shift(period.stepMonths) : null,
            ),
          ],
        ),
      ],
    );
  }
}
