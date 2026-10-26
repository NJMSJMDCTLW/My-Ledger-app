import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/hkd_converter.dart';
import 'package:hello_ledger/data/providers.dart';

Account account(int id, String currency, {int opening = 0}) {
  return Account(
    id: id,
    name: 'A$id',
    type: AccountType.bank,
    currency: currency,
    openingBalance: opening,
    isArchived: false,
  );
}

ExchangeRate rate(String currency, double r) =>
    ExchangeRate(
      currency: currency,
      rateToHkd: r,
      updatedAt: DateTime(2026),
    );

TransactionRecord tx(
  int accountId,
  int amount, {
  TransactionType type = TransactionType.expense,
  int? toAccountId,
  int? toAmount,
  int? categoryId = 1,
  DateTime? date,
}) {
  return TransactionRecord(
    id: 0,
    date: date ?? DateTime(2026, 10, 5),
    amount: amount,
    type: type,
    accountId: accountId,
    toAccountId: toAccountId,
    toAmount: toAmount,
    categoryId: categoryId,
    note: '',
    createdAt: DateTime(2026, 10, 5),
  );
}

void main() {
  final converter = HkdConverter.from(
    accounts: [account(1, 'HKD'), account(2, 'USD'), account(3, 'JPY')],
    rates: [rate('USD', 7.8), rate('JPY', 0.052)],
  );

  group('HkdConverter', () {
    test('港幣不用換算，外幣乘上匯率並四捨五入', () {
      expect(converter.toHkd(10000, 'HKD'), 10000);
      expect(converter.toHkd(10000, 'USD'), 78000); // 100 USD = 780 HKD
      expect(converter.toHkd(100000, 'JPY'), 5200); // 1000 JPY = 52 HKD
    });

    test('沒設定匯率的外幣當作 0，並且 hasRate 為 false', () {
      expect(converter.hasRate('EUR'), isFalse);
      expect(converter.toHkd(10000, 'EUR'), 0);
      expect(converter.hasRate('HKD'), isTrue);
    });

    test('兩種外幣互相換算', () {
      // 100 USD = 780 HKD = 15000 JPY
      expect(converter.convert(10000, 'USD', 'JPY'), 1500000);
      expect(converter.convert(10000, 'USD', 'USD'), 10000);
      expect(converter.convert(10000, 'USD', 'EUR'), isNull);
    });

    test('交易金額用所屬帳戶的貨幣折算', () {
      expect(converter.amountOf(tx(2, 10000)), 78000);
      expect(converter.amountOf(tx(1, 10000)), 10000);
    });
  });

  group('computeBalances', () {
    test('收入、支出、同幣別轉帳', () {
      final b = computeBalances(
        [account(1, 'HKD', opening: 1000), account(4, 'HKD')],
        [
          tx(1, 300),
          tx(1, 500, type: TransactionType.income),
          tx(1, 200, type: TransactionType.transfer, toAccountId: 4),
        ],
      );
      expect(b[1], 1000 - 300 + 500 - 200);
      expect(b[4], 200);
    });

    test('跨貨幣轉帳：轉入帳戶收到 toAmount', () {
      // 從港幣帳戶轉 780 HKD 到美元帳戶，收到 100 USD
      final b = computeBalances(
        [account(1, 'HKD', opening: 100000), account(2, 'USD')],
        [
          tx(1, 78000,
              type: TransactionType.transfer, toAccountId: 2, toAmount: 10000),
        ],
      );
      expect(b[1], 22000);
      expect(b[2], 10000);
    });

    test('沒有 toAmount 就和轉出金額一樣；已封存帳戶不計入', () {
      final b = computeBalances(
        [account(1, 'HKD', opening: 1000)],
        [tx(1, 100, type: TransactionType.transfer, toAccountId: 99)],
      );
      expect(b, {1: 900});
    });
  });

  group('統計折成港幣', () {
    final all = [
      tx(1, 10000), // 100 HKD
      tx(2, 1000), // 10 USD = 78 HKD
      tx(2, 2000, type: TransactionType.income), // 20 USD = 156 HKD
    ];

    test('有給換算器：外幣折成港幣再加總', () {
      final s = computeMonthlyStats(all, DateTime(2026, 10),
          converter: converter);
      expect(s.expense, 10000 + 7800);
      expect(s.income, 15600);
    });

    test('沒給換算器：維持原本的數字（相容舊行為）', () {
      final s = computeMonthlyStats(all, DateTime(2026, 10));
      expect(s.expense, 11000);
    });
  });

  group('formatMoney', () {
    test('加上貨幣符號，負數的負號在最前面', () {
      expect(formatMoney(12345, 'HKD'), 'HK\$123.45');
      expect(formatMoney(12345, 'USD'), 'US\$123.45');
      expect(formatMoney(-12345, 'JPY'), '-JP¥123.45');
    });
  });
}
