import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/l10n/app_localizations_en.dart';
import 'package:hello_ledger/l10n/app_localizations_zh.dart';
import 'package:hello_ledger/presentation/widgets/delta_text.dart';

TransactionRecord tx(
  DateTime date,
  int amount, {
  TransactionType type = TransactionType.expense,
  int? categoryId = 1,
}) {
  return TransactionRecord(
    id: 0,
    date: date,
    amount: amount,
    type: type,
    accountId: 1,
    categoryId: categoryId,
    note: '',
    createdAt: date,
  );
}

void main() {
  final en = AppLocalizationsEn();
  final zh = AppLocalizationsZh();

  group('DeltaText.describe', () {
    test('The comparison wording follows the language', () {
      expect(DeltaText.describe(zh, 100, 100), '與上月持平');
      expect(DeltaText.describe(zh, 100, 0), '上月無資料');
      expect(
        DeltaText.describe(en, 100, 100, previousName: 'last year'),
        'Same as last year',
      );
      expect(
        DeltaText.describe(zh, 100, 0, previousName: '去年'),
        '去年無資料',
      );
    });

    test('Increase and decrease show the difference and percentage', () {
      expect(DeltaText.describe(en, 125000, 100000), '▲ 250.00 (+25%)');
      expect(DeltaText.describe(en, 75000, 100000), '▼ 250.00 (-25%)');
    });

    test('Percentage only', () {
      expect(DeltaText.describe(en, 150, 100, showAmount: false), '▲ 50%');
    });

    test('Unchanged, and previous period is 0', () {
      expect(DeltaText.describe(en, 100, 100), 'Same as last month');
      expect(DeltaText.describe(en, 0, 0), 'Same as last month');
      expect(DeltaText.describe(en, 100, 0), 'No data for last month');
      expect(DeltaText.describe(en, 100, 0, noPreviousLabel: 'New'), 'New');
    });

    test('When the previous balance is negative, the percentage uses its absolute value', () {
      // From -100 to +50, a difference of 150, which is 150% of 100
      expect(DeltaText.describe(en, 5000, -10000), '▲ 150.00 (+150%)');
    });
  });

  group('computeMonthlyStats', () {
    final all = [
      tx(DateTime(2026, 10, 5), 1000, categoryId: 1),
      tx(DateTime(2026, 10, 6), 500, categoryId: 2),
      tx(DateTime(2026, 10, 7), 3000, type: TransactionType.income),
      tx(DateTime(2026, 9, 20), 800, categoryId: 1),
      tx(DateTime(2025, 12, 31), 400, categoryId: 3),
    ];

    test('Only counts the given month, with expense categories from largest to smallest', () {
      final s = computeMonthlyStats(all, DateTime(2026, 10));
      expect(s.expense, 1500);
      expect(s.income, 3000);
      expect(s.balance, 1500);
      expect(s.categoryRows.map((e) => e.key), [1, 2]);
    });

    test('The month before January is December of the previous year', () {
      final jan = DateTime(2026, 1);
      final prev = computeMonthlyStats(all, DateTime(jan.year, jan.month - 1));
      expect(prev.expense, 400);
      expect(prev.categoryRows.single.key, 3);
    });
  });
}
