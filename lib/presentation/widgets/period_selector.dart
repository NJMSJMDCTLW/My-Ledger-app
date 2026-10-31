import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/stats_range.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';

/// The top of the statistics tab: switches between monthly / last six months / one year, plus the arrows that move back and forward.
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  /// The title text for the current range.
  static String title(AppLocalizations l10n, StatsPeriod period, StatsRange range) {
    final last = DateTime(range.end.year, range.end.month - 1);
    return switch (period) {
      StatsPeriod.month => l10n.monthTitle(range.start),
      StatsPeriod.sixMonths => l10n.dateRange(
          l10n.formatYearMonth(range.start), l10n.formatYearMonth(last)),
      StatsPeriod.year => l10n.formatYear(range.start),
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
                ButtonSegment(value: p, label: Text(p.label(context.l10n))),
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
              tooltip: context.l10n.tooltipGoBack,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => notifier.shift(-period.stepMonths),
            ),
            Text(
              title(context.l10n, period, range),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              tooltip: context.l10n.tooltipGoForward,
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
