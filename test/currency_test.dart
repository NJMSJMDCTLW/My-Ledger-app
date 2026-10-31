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
      isManual: false,
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
    test('HKD needs no conversion; foreign amounts are multiplied by the rate and rounded', () {
      expect(converter.toHkd(10000, 'HKD'), 10000);
      expect(converter.toHkd(10000, 'USD'), 78000); // 100 USD = 780 HKD
      expect(converter.toHkd(100000, 'JPY'), 5200); // 1000 JPY = 52 HKD
    });

    test('A foreign currency with no rate counts as 0 and hasRate is false', () {
      expect(converter.hasRate('EUR'), isFalse);
      expect(converter.toHkd(10000, 'EUR'), 0);
      expect(converter.hasRate('HKD'), isTrue);
    });

    test('Converting between two foreign currencies', () {
      // 100 USD = 780 HKD = 15000 JPY
      expect(converter.convert(10000, 'USD', 'JPY'), 1500000);
      expect(converter.convert(10000, 'USD', 'USD'), 10000);
      expect(converter.convert(10000, 'USD', 'EUR'), isNull);
    });

    test('A transaction amount is converted using its account currency', () {
      expect(converter.amountOf(tx(2, 10000)), 78000);
      expect(converter.amountOf(tx(1, 10000)), 10000);
    });
  });

  group('computeBalances', () {
    test('Income, expense and same-currency transfers', () {
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

    test('Cross-currency transfer: the destination account receives toAmount', () {
      // Transfer 780 HKD from an HKD account to a USD account, which receives 100 USD
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

    test('Without toAmount it equals the amount sent; archived accounts are not counted', () {
      final b = computeBalances(
        [account(1, 'HKD', opening: 1000)],
        [tx(1, 100, type: TransactionType.transfer, toAccountId: 99)],
      );
      expect(b, {1: 900});
    });
  });

  group('Statistics converted to HKD', () {
    final all = [
      tx(1, 10000), // 100 HKD
      tx(2, 1000), // 10 USD = 78 HKD
      tx(2, 2000, type: TransactionType.income), // 20 USD = 156 HKD
    ];

    test('With a converter: foreign amounts are converted to HKD, then summed', () {
      final s = computeMonthlyStats(all, DateTime(2026, 10),
          converter: converter);
      expect(s.expense, 10000 + 7800);
      expect(s.income, 15600);
    });

    test('Without a converter: the original numbers are kept (backward compatible)', () {
      final s = computeMonthlyStats(all, DateTime(2026, 10));
      expect(s.expense, 11000);
    });
  });

  group('formatMoney', () {
    test('Adds the currency symbol, with the minus sign in front for negatives', () {
      expect(formatMoney(12345, 'HKD'), 'HK\$123.45');
      expect(formatMoney(12345, 'USD'), 'US\$123.45');
      expect(formatMoney(-12345, 'JPY'), '-JP¥123.45');
    });
  });
}
