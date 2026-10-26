import 'package:flutter/material.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/widgets/delta_text.dart';

/// 「與上一期比較」卡片：收入、支出、結餘各自的這期、上期與差額。
/// [title] 例如「與上個月比較（9 月）」，[previousName] 例如「上月」「前六個月」「去年」。
class PeriodComparison extends StatelessWidget {
  const PeriodComparison({
    super.key,
    required this.title,
    required this.previousName,
    required this.current,
    required this.previous,
  });

  final String title;
  final String previousName;
  final MonthlyStats current;
  final MonthlyStats previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrevious = previous.txs.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            if (!hasPrevious)
              Text('$previousName沒有紀錄，無法比較', style: theme.textTheme.bodyMedium)
            else ...[
              _Row(
                label: '支出',
                previousName: previousName,
                current: current.expense,
                previous: previous.expense,
                higherIsBad: true,
              ),
              _Row(
                label: '收入',
                previousName: previousName,
                current: current.income,
                previous: previous.income,
                higherIsBad: false,
              ),
              _Row(
                label: '結餘',
                previousName: previousName,
                current: current.balance,
                previous: previous.balance,
                higherIsBad: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.previousName,
    required this.current,
    required this.previous,
    required this.higherIsBad,
  });

  final String label;
  final String previousName;
  final int current;
  final int previous;
  final bool higherIsBad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(label)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCents(current),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '$previousName ${formatCents(previous)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          DeltaText(
            current: current,
            previous: previous,
            higherIsBad: higherIsBad,
            previousName: previousName,
          ),
        ],
      ),
    );
  }
}
