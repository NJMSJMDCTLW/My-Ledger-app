import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,##0.00');

/// 把「分」轉成顯示字串，例如 12345 -> 123.45
String formatCents(int cents) => _fmt.format(cents / 100);

/// 把使用者輸入的字串轉成「分」。格式不對回傳 null。
int? parseCents(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', ''));
  if (value == null) return null;
  return (value * 100).round();
}
