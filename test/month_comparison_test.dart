import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
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
  group('DeltaText.describe', () {
    test('增加與減少，顯示差額與百分比', () {
      expect(DeltaText.describe(125000, 100000), '▲ 250.00 (+25%)');
      expect(DeltaText.describe(75000, 100000), '▼ 250.00 (-25%)');
    });

    test('只顯示百分比', () {
      expect(DeltaText.describe(150, 100, showAmount: false), '▲ 50%');
    });

    test('持平與上月為 0', () {
      expect(DeltaText.describe(100, 100), '與上月持平');
      expect(DeltaText.describe(0, 0), '與上月持平');
      expect(DeltaText.describe(100, 0), '上月無資料');
      expect(DeltaText.describe(100, 0, noPreviousLabel: '新增'), '新增');
    });

    test('上月結餘是負數時，百分比用絕對值計算', () {
      // 從 -100 變成 +50，差 150，相對於 100 是 150%
      expect(DeltaText.describe(5000, -10000), '▲ 150.00 (+150%)');
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

    test('只統計該月份，支出類別由大到小', () {
      final s = computeMonthlyStats(all, DateTime(2026, 10));
      expect(s.expense, 1500);
      expect(s.income, 3000);
      expect(s.balance, 1500);
      expect(s.categoryRows.map((e) => e.key), [1, 2]);
    });

    test('一月的「上個月」是去年十二月', () {
      final jan = DateTime(2026, 1);
      final prev = computeMonthlyStats(all, DateTime(jan.year, jan.month - 1));
      expect(prev.expense, 400);
      expect(prev.categoryRows.single.key, 3);
    });
  });
}
