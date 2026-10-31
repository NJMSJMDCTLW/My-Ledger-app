// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Ledger';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageFollowSystem => 'Follow system';

  @override
  String get languageFollowSystemHint =>
      'Uses Traditional Chinese when the phone is set to Chinese, and English otherwise.';

  @override
  String get navHome => 'Home';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navCreditCards => 'Credit cards';

  @override
  String get navRecurring => 'Recurring';

  @override
  String get navCategories => 'Categories';

  @override
  String get navRates => 'Exchange rates';

  @override
  String get fabAddTransaction => 'Add transaction';

  @override
  String get fabAddAccount => 'Add account';

  @override
  String get fabAddCreditCard => 'Add credit card';

  @override
  String get fabAddRecurring => 'Add recurring';

  @override
  String get fabAddCategory => 'Add category';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get expenseCategories => 'Expenses by category';

  @override
  String get viewStatisticsTooltip => 'View detailed statistics';

  @override
  String get transactionsHeading => 'Transactions';

  @override
  String get noTransactionsThisMonth => 'No transactions this month';

  @override
  String transferTitle(String from, String to) {
    return 'Transfer: $from → $to';
  }

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String balanceAmount(String amount) {
    return 'Balance $amount';
  }

  @override
  String dayHeader(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get tooltipPreviousMonth => 'Previous month';

  @override
  String get tooltipNextMonth => 'Next month';

  @override
  String monthTitle(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get noExpensesThisMonth => 'No expenses this month';

  @override
  String get totalExpense => 'Total expense';

  @override
  String get comparisonNew => 'New';

  @override
  String originalAmount(String amount) {
    return 'Original $amount';
  }

  @override
  String get listSeparator => ', ';

  @override
  String ratesMissingWarning(String currencies) {
    return 'No exchange rate is set for $currencies, so the HKD amounts are incomplete. Set it under Exchange rates in the drawer.';
  }

  @override
  String get ratesConvertedNote =>
      'Foreign currencies are converted to HKD using the rates on the Exchange rates tab.';

  @override
  String get periodLastMonth => 'last month';

  @override
  String comparisonSame(String previous) {
    return 'Same as $previous';
  }

  @override
  String comparisonNoData(String previous) {
    return 'No data for $previous';
  }
}
