/// Four-function arithmetic for the calculator: + − × ÷, decimals, multiplication/division before addition/subtraction.
///
/// An incomplete expression (empty, or ending in an operator) ignores the trailing operator;
/// division by zero or a malformed expression returns null.
double? evaluateExpression(String expression) {
  // Normalize symbols and strip trailing operators (e.g. the user typed "12+")
  var s = expression
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll(' ', '');
  while (s.isNotEmpty && '+-*/'.contains(s[s.length - 1])) {
    s = s.substring(0, s.length - 1);
  }
  if (s.isEmpty) return null;

  // Split into numbers and operators
  final tokens = <Object>[]; // double or String (an operator)
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if ('+-*/'.contains(ch)) {
      if (buffer.isEmpty) {
        // A leading minus sign belongs to the number
        if (ch == '-' && (tokens.isEmpty || tokens.last is String)) {
          buffer.write(ch);
          continue;
        }
        return null;
      }
      final n = double.tryParse(buffer.toString());
      if (n == null) return null;
      tokens
        ..add(n)
        ..add(ch);
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  final last = double.tryParse(buffer.toString());
  if (last == null) return null;
  tokens.add(last);

  // Handle multiplication and division first
  final addSub = <Object>[tokens.first];
  for (var i = 1; i < tokens.length; i += 2) {
    final op = tokens[i] as String;
    final right = tokens[i + 1] as double;
    if (op == '*' || op == '/') {
      final left = addSub.removeLast() as double;
      if (op == '/' && right == 0) return null;
      addSub.add(op == '*' ? left * right : left / right);
    } else {
      addSub
        ..add(op)
        ..add(right);
    }
  }

  // Then addition and subtraction
  var result = addSub.first as double;
  for (var i = 1; i < addSub.length; i += 2) {
    final right = addSub[i + 1] as double;
    result = addSub[i] == '+' ? result + right : result - right;
  }
  return result;
}

/// Turns an expression result into the string for the input field, always two decimals (avoids floating-point errors like 0.1+0.2).
String formatCalculatorResult(double value) {
  return ((value * 100).round() / 100).toStringAsFixed(2);
}
