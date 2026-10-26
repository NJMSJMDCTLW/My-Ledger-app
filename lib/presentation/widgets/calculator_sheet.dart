import 'package:flutter/material.dart';
import 'package:hello_ledger/core/calculator.dart';

/// 打開計算機，回傳使用者按「完成」時的金額字串（兩位小數）。取消或算式無效回傳 null。
Future<String?> showCalculator(BuildContext context, {String initial = ''}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CalculatorSheet(initial: initial),
  );
}

class _CalculatorSheet extends StatefulWidget {
  const _CalculatorSheet({required this.initial});

  final String initial;

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  static const _operators = ['+', '−', '×', '÷'];

  late String _expr = _initialExpression(widget.initial);

  /// 帶入原本的金額；0 或空的就從空白開始。
  static String _initialExpression(String initial) {
    final value = double.tryParse(initial);
    if (value == null || value == 0) return '';
    return initial.endsWith('.00')
        ? initial.substring(0, initial.length - 3)
        : initial;
  }

  bool get _endsWithOperator =>
      _expr.isNotEmpty && _operators.contains(_expr[_expr.length - 1]);

  /// 目前正在輸入的那個數字（最後一個運算符號之後的部分）。
  String get _currentNumber {
    var i = _expr.length;
    while (i > 0 && !_operators.contains(_expr[i - 1])) {
      i--;
    }
    return _expr.substring(i);
  }

  double? get _value => evaluateExpression(_expr);

  void _press(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expr = '';
        case '⌫':
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        case '+' || '−' || '×' || '÷':
          if (_expr.isEmpty) {
            if (key == '−') _expr = key; // 允許負數開頭
          } else if (_endsWithOperator) {
            // 連按兩個符號，後面的取代前面的
            _expr = _expr.substring(0, _expr.length - 1) + key;
          } else {
            _expr += key;
          }
        case '.':
          if (!_currentNumber.contains('.')) {
            _expr += _currentNumber.isEmpty ? '0.' : '.';
          }
        case '=':
          final v = _value;
          if (v != null) _expr = _trim(formatCalculatorResult(v));
        default: // 數字
          // 小數最多兩位
          final cur = _currentNumber;
          if (cur.contains('.') && cur.split('.').last.length >= 2) return;
          _expr += key;
      }
    });
  }

  String _trim(String s) => s.endsWith('.00') ? s.substring(0, s.length - 3) : s;

  void _done() {
    final v = _value;
    if (v == null || v <= 0) return;
    Navigator.pop(context, formatCalculatorResult(v));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _value;
    final hasOperation = _expr.contains(RegExp(r'[+×÷]')) ||
        (_expr.length > 1 && _expr.substring(1).contains('−'));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顯示區
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasOperation && value != null
                        ? '= ${formatCalculatorResult(value)}'
                        : ' ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _expr.isEmpty ? '0' : _expr,
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final row in const [
              ['C', '⌫', '÷', '×'],
              ['7', '8', '9', '−'],
              ['4', '5', '6', '+'],
              ['1', '2', '3', '='],
            ])
              Row(
                children: [
                  for (final k in row)
                    _Key(
                      label: k,
                      isOperator: _operators.contains(k) || k == '=',
                      onTap: () => _press(k),
                    ),
                ],
              ),
            Row(
              children: [
                _Key(label: '0', onTap: () => _press('0')),
                _Key(label: '.', onTap: () => _press('.')),
                _Key(
                  label: '完成',
                  flex: 2,
                  filled: true,
                  onTap: (value != null && value > 0) ? _done : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.filled = false,
    this.flex = 1,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isOperator;
  final bool filled;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = filled
        ? scheme.primary
        : isOperator
            ? scheme.primaryContainer
            : scheme.surfaceContainerLowest;
    final foreground = filled ? scheme.onPrimary : scheme.onSurface;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: onTap == null ? scheme.surfaceContainerHighest : background,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: filled ? FontWeight.bold : FontWeight.w500,
                    color: onTap == null ? scheme.outline : foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
