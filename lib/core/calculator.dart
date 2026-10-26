/// 計算機用的四則運算，支援 + − × ÷、小數、先乘除後加減。
///
/// 算式不完整（空的、結尾是運算符號）時會忽略結尾的符號；
/// 除以 0 或格式錯誤回傳 null。
double? evaluateExpression(String expression) {
  // 統一符號，並去掉結尾多餘的運算符號（例如使用者打到「12+」）
  var s = expression
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll(' ', '');
  while (s.isNotEmpty && '+-*/'.contains(s[s.length - 1])) {
    s = s.substring(0, s.length - 1);
  }
  if (s.isEmpty) return null;

  // 切成數字與運算符號
  final tokens = <Object>[]; // double 或 String（運算符號）
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if ('+-*/'.contains(ch)) {
      if (buffer.isEmpty) {
        // 開頭的負號：併入數字
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

  // 先處理乘除
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

  // 再處理加減
  var result = addSub.first as double;
  for (var i = 1; i < addSub.length; i += 2) {
    final right = addSub[i + 1] as double;
    result = addSub[i] == '+' ? result + right : result - right;
  }
  return result;
}

/// 把算式結果轉成輸入框要用的字串，固定兩位小數（避免 0.1+0.2 這類浮點誤差）。
String formatCalculatorResult(double value) {
  return ((value * 100).round() / 100).toStringAsFixed(2);
}
