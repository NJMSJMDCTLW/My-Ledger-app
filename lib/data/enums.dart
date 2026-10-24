enum AccountType { bank, cash, creditCard, eWallet }

enum CategoryType { expense, income }

enum TransactionType { expense, income, transfer }

extension AccountTypeLabel on AccountType {
  String get label => switch (this) {
        AccountType.bank => '銀行帳戶',
        AccountType.cash => '現金',
        AccountType.creditCard => '信用卡',
        AccountType.eWallet => '電子錢包',
      };
}

extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
        TransactionType.expense => '支出',
        TransactionType.income => '收入',
        TransactionType.transfer => '轉帳',
      };
}
