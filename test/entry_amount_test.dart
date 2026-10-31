import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/entry_amount.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/hkd_converter.dart';

Account account(int id, String currency) => Account(
      id: id,
      name: 'A$id',
      type: AccountType.bank,
      currency: currency,
      openingBalance: 0,
      isArchived: false,
    );

ExchangeRate rate(String c, double r) => ExchangeRate(
      currency: c,
      rateToHkd: r,
      isManual: false,
      updatedAt: DateTime(2026),
    );

TransactionRecord existingTx({
  required int amount,
  int accountId = 1,
  int? originalAmount,
  String? originalCurrency,
}) {
  return TransactionRecord(
    id: 1,
    date: DateTime(2026, 10, 1),
    amount: amount,
    type: TransactionType.expense,
    accountId: accountId,
    originalAmount: originalAmount,
    originalCurrency: originalCurrency,
    note: '',
    createdAt: DateTime(2026, 10, 1),
  );
}

void main() {
  // Account 1 is HKD, account 2 is USD
  final converter = HkdConverter.from(
    accounts: [account(1, 'HKD'), account(2, 'USD')],
    rates: [rate('USD', 7.8), rate('JPY', 0.05)],
  );

  test('Entry currency equals the account currency: no conversion, no original value', () {
    final r = resolveEntryAmount(
      enteredCents: 5000,
      entryCurrency: 'HKD',
      accountId: 1,
      converter: converter,
    )!;
    expect(r.amount, 5000);
    expect(r.originalAmount, isNull);
    expect(r.originalCurrency, isNull);
  });

  test('Paying in USD but recording to an HKD account: converted to HKD at the rate, keeping the original value', () {
    final r = resolveEntryAmount(
      enteredCents: 1000, // US$10
      entryCurrency: 'USD',
      accountId: 1,
      converter: converter,
    )!;
    expect(r.amount, 7800); // HK$78
    expect(r.originalAmount, 1000);
    expect(r.originalCurrency, 'USD');
  });

  test('Paying in JPY and recording to a USD account: two foreign currencies converted', () {
    final r = resolveEntryAmount(
      enteredCents: 156000, // JP¥1,560 = HK$78 = US$10
      entryCurrency: 'JPY',
      accountId: 2,
      converter: converter,
    )!;
    expect(r.amount, 1000);
    expect(r.originalCurrency, 'JPY');
  });

  test('Cannot convert when no rate is set', () {
    expect(
      resolveEntryAmount(
        enteredCents: 1000,
        entryCurrency: 'EUR',
        accountId: 1,
        converter: converter,
      ),
      isNull,
    );
  });

  test('Editing with unchanged input: keeps the stored amount, so it does not drift when the rate changes', () {
    // The rate back then was 7.0, recorded as HK$70; the rate is 7.8 now
    final r = resolveEntryAmount(
      enteredCents: 1000,
      entryCurrency: 'USD',
      accountId: 1,
      converter: converter,
      existing: existingTx(
        amount: 7000,
        originalAmount: 1000,
        originalCurrency: 'USD',
      ),
    )!;
    expect(r.amount, 7000);
  });

  test('Editing the amount or switching account: converts again at the current rate', () {
    final changedAmount = resolveEntryAmount(
      enteredCents: 2000,
      entryCurrency: 'USD',
      accountId: 1,
      converter: converter,
      existing: existingTx(
          amount: 7000, originalAmount: 1000, originalCurrency: 'USD'),
    )!;
    expect(changedAmount.amount, 15600);

    final changedAccount = resolveEntryAmount(
      enteredCents: 1000,
      entryCurrency: 'JPY',
      accountId: 1,
      converter: converter,
      existing: existingTx(
          amount: 7000,
          accountId: 2,
          originalAmount: 1000,
          originalCurrency: 'JPY'),
    )!;
    expect(changedAccount.amount, 50); // 1000 cents of JPY = 10 JPY = HK$0.5
  });
}
