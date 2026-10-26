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
  // 帳戶 1 是港幣，帳戶 2 是美元
  final converter = HkdConverter.from(
    accounts: [account(1, 'HKD'), account(2, 'USD')],
    rates: [rate('USD', 7.8), rate('JPY', 0.05)],
  );

  test('輸入貨幣和帳戶一樣：不換算，沒有原始值', () {
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

  test('用美元付款但記在港幣帳戶：依匯率換成港幣，並保留原始值', () {
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

  test('用日圓付款記在美元帳戶：兩種外幣互換', () {
    final r = resolveEntryAmount(
      enteredCents: 156000, // JP¥1,560 = HK$78 = US$10
      entryCurrency: 'JPY',
      accountId: 2,
      converter: converter,
    )!;
    expect(r.amount, 1000);
    expect(r.originalCurrency, 'JPY');
  });

  test('沒有設定匯率就換算不了', () {
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

  test('編輯時輸入沒變：沿用原本的金額，不會因為匯率變了而跑掉', () {
    // 當時匯率是 7.0，記成 HK$70；現在匯率是 7.8
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

  test('編輯時改了金額或換了帳戶：重新依目前匯率換算', () {
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
    expect(changedAccount.amount, 50); // 1000 分日圓 = 10 JPY = HK$0.5
  });
}
