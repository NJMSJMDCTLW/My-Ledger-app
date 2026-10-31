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
    test('Four operations and precedence', () {
      expect(evaluateExpression('12+3×4'), 24);
      expect(evaluateExpression('100−20÷4'), 95);
      expect(evaluateExpression('2×3+4×5'), 26);
      expect(evaluateExpression('10÷4'), 2.5);
    });

    test('Decimals and trailing operators', () {
      expect(evaluateExpression('1.5+2.25'), 3.75);
      expect(evaluateExpression('12+'), 12);
      expect(evaluateExpression('12+3×'), 15);
    });

    test('Leading negative sign', () {
      expect(evaluateExpression('−5+8'), 3);
    });

    test('Invalid expressions return null', () {
      expect(evaluateExpression(''), isNull);
      expect(evaluateExpression('+'), isNull);
      expect(evaluateExpression('5÷0'), isNull);
      expect(evaluateExpression('1..2+3'), isNull);
    });

    test('Floating-point errors are rounded to two decimals', () {
      expect(formatCalculatorResult(evaluateExpression('0.1+0.2')!), '0.30');
      expect(formatCalculatorResult(10 / 3), '3.33');
    });
  });

  group('suggestNotes', () {
    test('Only suggests notes used in the same category, most used first', () {
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

    test('No suggestions until a category is chosen', () {
      final list = suggestNotes(
        [tx('晚餐', categoryId: 1)],
        type: TransactionType.expense,
      );
      expect(list, isEmpty);
    });

    test('A transfer has no category, so all transfer notes are suggested', () {
      final list = suggestNotes(
        [
          tx('還朋友', categoryId: null, type: TransactionType.transfer),
          tx('晚餐'),
        ],
        type: TransactionType.transfer,
      );
      expect(list, ['還朋友']);
    });

    test('Only suggests notes of the same type, ignores blank notes, and can filter by text', () {
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

    test('When counts are equal, the most recently used comes first', () {
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
