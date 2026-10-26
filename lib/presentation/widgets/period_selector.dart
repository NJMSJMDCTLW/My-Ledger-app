import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/stats_range.dart';

/// 統計分頁頂端：切換「每月 / 近六個月 / 一年」，以及往前後移動的箭頭。
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  static String _ym(DateTime d) => '${d.year}/${d.month}';

  /// 目前範圍的標題文字。
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

    // 已經是最新的一期就不能再往後：看的範圍最後一個月 >= 這個月
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
