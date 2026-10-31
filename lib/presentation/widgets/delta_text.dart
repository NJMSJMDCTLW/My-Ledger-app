import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/money.dart';

/// Text comparing with the previous period, e.g. "▲ 120.00 (+25%)".
///
/// When [higherIsBad] is true (expenses), an increase is red and a decrease is green;
/// when false (income, balance) it is the other way round.
class DeltaText extends StatelessWidget {
  const DeltaText({
    super.key,
    required this.current,
    required this.previous,
    required this.higherIsBad,
    this.showAmount = true,
    this.previousName = '上月',
    this.noPreviousLabel,
  });

  final int current;
  final int previous;
  final bool higherIsBad;

  /// Whether to show the difference amount; places with little room show only the percentage.
  final bool showAmount;

  /// Name of the comparison target, e.g. "last month", "the previous six months", "last year".
  final String previousName;

  /// Text shown when the previous period is 0 and this period has an amount (the category breakdown uses "new"). Defaults to "no data for ...".
  final String? noPreviousLabel;

  /// Builds the comparison text. When the previous period is 0 there is no percentage to compute.
  static String describe(
    int current,
    int previous, {
    bool showAmount = true,
    String previousName = '上月',
    String? noPreviousLabel,
  }) {
    final diff = current - previous;
    if (diff == 0) return '與$previousName持平';
    if (previous == 0) return noPreviousLabel ?? '$previousName無資料';

    final arrow = diff > 0 ? '▲' : '▼';
    final pct = (diff.abs() / previous.abs() * 100).round();
    final sign = diff > 0 ? '+' : '-';
    return showAmount
        ? '$arrow ${formatCents(diff.abs())} ($sign$pct%)'
        : '$arrow $pct%';
  }

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final Color? color;
    if (diff == 0 || previous == 0) {
      color = Theme.of(context).hintColor;
    } else {
      final isGood = higherIsBad ? diff < 0 : diff > 0;
      color = isGood ? AppTheme.income : AppTheme.expense;
    }

    return Text(
      describe(
        current,
        previous,
        showAmount: showAmount,
        previousName: previousName,
        noPreviousLabel: noPreviousLabel,
      ),
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}
