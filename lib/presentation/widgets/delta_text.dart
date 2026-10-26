import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/money.dart';

/// 和上一期比較的文字，例如「▲ 120.00 (+25%)」。
///
/// [higherIsBad] 為 true 時（支出），增加是紅色、減少是綠色；
/// 為 false 時（收入、結餘）剛好相反。
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

  /// 是否顯示差額金額；列表空間小的地方只顯示百分比。
  final bool showAmount;

  /// 比較對象的名稱，例如「上月」「前六個月」「去年」。
  final String previousName;

  /// 上一期是 0、這一期有金額時顯示的字（類別明細會用「新增」）。沒給就用「○○無資料」。
  final String? noPreviousLabel;

  /// 計算比較結果的文字。上一期是 0 時沒有百分比可算。
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
