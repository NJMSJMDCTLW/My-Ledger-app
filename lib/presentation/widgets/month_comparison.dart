import 'package:flutter/material.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/widgets/delta_text.dart';
import 'package:intl/intl.dart';

/// 「與上個月比較」卡片：收入、支出、結餘各自的本月、上月與差額。
class MonthComparison extends StatelessWidget {
  const MonthComparison({
    super.key,
    required this.month,
    required this.current,
    required this.previous,
  });

  final DateTime month;
  final MonthlyStats current;
  final MonthlyStats previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prevMonth = DateTime(month.year, month.month - 1);
    final hasPrevious = previous.txs.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '與上個月比較（${DateFormat('M 月').format(prevMonth)}）',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            if (!hasPrevious)
              Text('上個月沒有紀錄，無法比較', style: theme.textTheme.bodyMedium)
            else ...[
              _Row(
                label: '支出',
                current: current.expense,
                previous: previous.expense,
                higherIsBad: true,
              ),
              _Row(
                label: '收入',
                current: current.income,
                previous: previous.income,
                higherIsBad: false,
              ),
              _Row(
                label: '結餘',
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
    required this.current,
    required this.previous,
    required this.higherIsBad,
  });

  final String label;
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
                  '上月 ${formatCents(previous)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          DeltaText(
            current: current,
            previous: previous,
            higherIsBad: higherIsBad,
          ),
        ],
      ),
    );
  }
}
