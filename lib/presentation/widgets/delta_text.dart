import 'package:flutter/material.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/money.dart';

/// 和上個月比較的文字，例如「▲ 120.00 (+25%)」。
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
    this.noPreviousLabel = '上月無資料',
  });

  final int current;
  final int previous;
  final bool higherIsBad;

  /// 是否顯示差額金額；列表空間小的地方只顯示百分比。
  final bool showAmount;

  /// 上個月是 0、本月有金額時顯示的字（類別明細會用「新增」）。
  final String noPreviousLabel;

  /// 計算比較結果的文字。上個月是 0 時沒有百分比可算。
  static String describe(
    int current,
    int previous, {
    bool showAmount = true,
    String noPreviousLabel = '上月無資料',
  }) {
    final diff = current - previous;
    if (diff == 0) return '與上月持平';
    if (previous == 0) return noPreviousLabel;

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
        noPreviousLabel: noPreviousLabel,
      ),
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}
