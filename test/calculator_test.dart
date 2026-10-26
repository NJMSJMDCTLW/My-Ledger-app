import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/calculator.dart';
import 'package:hello_ledger/core/note_suggestions.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

TransactionRecord tx(
  String note, {
  int? categoryId = 1,
  TransactionType type = TransactionType.expense,
  DateTime? date,
}) {
  return TransactionRecord(
    id: 0,
    date: date ?? DateTime(2026, 10, 1),
    amount: 100,
    type: type,
    accountId: 1,
    categoryId: categoryId,
    note: note,
    createdAt: DateTime(2026, 10, 1),
  );
}

void main() {
  group('evaluateExpression', () {
    test('四則運算與優先順序', () {
      expect(evaluateExpression('12+3×4'), 24);
      expect(evaluateExpression('100−20÷4'), 95);
      expect(evaluateExpression('2×3+4×5'), 26);
      expect(evaluateExpression('10÷4'), 2.5);
    });

    test('小數與結尾多餘的運算符號', () {
      expect(evaluateExpression('1.5+2.25'), 3.75);
      expect(evaluateExpression('12+'), 12);
      expect(evaluateExpression('12+3×'), 15);
    });

    test('負數開頭', () {
      expect(evaluateExpression('−5+8'), 3);
    });

    test('無效算式回傳 null', () {
      expect(evaluateExpression(''), isNull);
      expect(evaluateExpression('+'), isNull);
      expect(evaluateExpression('5÷0'), isNull);
      expect(evaluateExpression('1..2+3'), isNull);
    });

    test('浮點誤差會被修正成兩位小數', () {
      expect(formatCalculatorResult(evaluateExpression('0.1+0.2')!), '0.30');
      expect(formatCalculatorResult(10 / 3), '3.33');
    });
  });

  group('suggestNotes', () {
    test('只推薦同一個類別用過的備註，次數多的在前面', () {
      final list = suggestNotes(
        [
          tx('晚餐', categoryId: 1),
          tx('午餐', categoryId: 1),
          tx('午餐', categoryId: 1),
          tx('計程車', categoryId: 2),
          tx('計程車', categoryId: 2),
          tx('計程車', categoryId: 2),
        ],
        type: TransactionType.expense,
        categoryId: 1,
      );
      expect(list, ['午餐', '晚餐']);
    });

    test('還沒選類別就沒有推薦', () {
      final list = suggestNotes(
        [tx('晚餐', categoryId: 1)],
        type: TransactionType.expense,
      );
      expect(list, isEmpty);
    });

    test('轉帳沒有類別，推薦所有轉帳的備註', () {
      final list = suggestNotes(
        [
          tx('還朋友', categoryId: null, type: TransactionType.transfer),
          tx('晚餐'),
        ],
        type: TransactionType.transfer,
      );
      expect(list, ['還朋友']);
    });

    test('只推薦同類型、忽略空白備註、可以用文字篩選', () {
      final txs = [
        tx('薪水加給', type: TransactionType.income),
        tx('宵夜'),
        tx('   '),
        tx('晚餐'),
      ];
      expect(
        suggestNotes(txs, type: TransactionType.expense, categoryId: 1),
        unorderedEquals(['宵夜', '晚餐']),
      );
      expect(
        suggestNotes(txs,
            type: TransactionType.expense, categoryId: 1, query: '晚'),
        ['晚餐'],
      );
    });

    test('次數一樣時，最近用過的在前面', () {
      final list = suggestNotes(
        [
          tx('舊的', date: DateTime(2026, 1, 1)),
          tx('新的', date: DateTime(2026, 10, 1)),
        ],
        type: TransactionType.expense,
        categoryId: 1,
      );
      expect(list, ['新的', '舊的']);
    });
  });
}
