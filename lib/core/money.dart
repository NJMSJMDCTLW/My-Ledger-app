import 'package:hello_ledger/core/currencies.dart';
import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,##0.00');

/// Converts cents to a display string, e.g. 12345 -> 123.45
String formatCents(int cents) => _fmt.format(cents / 100);

/// Adds a currency symbol, e.g. 12345, USD -> US$123.45. A negative puts the minus sign before the symbol: -US$123.45.
String formatMoney(int cents, String currency) {
  final symbol = currencyInfo(currency).symbol;
  final text = '$symbol${_fmt.format(cents.abs() / 100)}';
  return cents < 0 ? '-$text' : text;
}

/// Converts a string the user typed into cents. Returns null if the format is invalid.
int? parseCents(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', ''));
  if (value == null) return null;
  return (value * 100).round();
}
