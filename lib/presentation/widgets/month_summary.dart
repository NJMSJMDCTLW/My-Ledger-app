import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/providers.dart';

/// 當月收入（綠）、支出（紅）、結餘（正數綠色、負數紅色）。
class MonthSummary extends StatelessWidget {
  const MonthSummary({super.key, required this.stats});

  final MonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _Item(label: '收入', cents: stats.income, color: AppTheme.income),
            _Item(label: '支出', cents: stats.expense, color: AppTheme.expense),
            _Item(
              label: '結餘',
              cents: stats.balance,
              color: AppTheme.balanceColor(stats.balance),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.cents, this.color});

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
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
