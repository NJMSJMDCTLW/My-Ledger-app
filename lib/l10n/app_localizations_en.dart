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

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get accountTypeBank => 'Bank account';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeCreditCard => 'Credit card';

  @override
  String get accountTypeEWallet => 'E-wallet';

  @override
  String get currencyNameHKD => 'Hong Kong dollar';

  @override
  String get currencyNameUSD => 'US dollar';

  @override
  String get currencyNameCNY => 'Chinese yuan';

  @override
  String get currencyNameTWD => 'New Taiwan dollar';

  @override
  String get currencyNameJPY => 'Japanese yen';

  @override
  String get currencyNameKRW => 'South Korean won';

  @override
  String get currencyNameEUR => 'Euro';

  @override
  String get currencyNameGBP => 'British pound';

  @override
  String get currencyNameSGD => 'Singapore dollar';

  @override
  String get currencyNameAUD => 'Australian dollar';

  @override
  String get currencyNameCAD => 'Canadian dollar';

  @override
  String get currencyNameTHB => 'Thai baht';

  @override
  String get accountsEmpty =>
      'No accounts yet. Tap the button at the bottom right to add one.';

  @override
  String get archivedAccounts => 'Archived accounts';

  @override
  String get rateNotSet => 'No exchange rate set';

  @override
  String get creditCardsEmpty =>
      'No credit cards yet. Tap the button at the bottom right to add one.';

  @override
  String creditDebt(String amount) {
    return 'Debt $amount';
  }

  @override
  String creditAvailable(String available, String limit) {
    return 'Available $available / $limit';
  }

  @override
  String get statementDayNotSet => 'Statement day: not set';

  @override
  String nextStatement(DateTime date, String when) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Next statement: $dateString ($when)';
  }

  @override
  String get dueDayNotSet => 'Due day: not set';

  @override
  String nextPayment(DateTime date, String when) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Next payment: $dateString ($when)';
  }

  @override
  String get payReminder => '⚠ Remember to pay';

  @override
  String daysFromNow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'tomorrow',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get addAccount => 'Add account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get archiveAccountTitle => 'Archive this account?';

  @override
  String get archiveAccountMessage =>
      'Once archived, it no longer appears in the account list or the total balance, and it can\'t be picked when recording. Past transactions are kept, and you can unarchive it at any time.';

  @override
  String get fieldName => 'Name';

  @override
  String get nameRequired => 'Enter a name';

  @override
  String get fieldAccountType => 'Type';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get currencyLockedHint =>
      'An account that already has records can\'t change its currency.';

  @override
  String rateFieldLabel(String currency) {
    return 'Exchange rate: 1 $currency = ? HKD';
  }

  @override
  String get rateFetching => 'Getting the latest rate automatically…';

  @override
  String get rateFetchFailedHint =>
      'Couldn\'t get it automatically. Tap the button on the right to retry, or enter it yourself. You can change it later on the Exchange rates tab.';

  @override
  String get rateFetchTooltip => 'Get the latest rate automatically';

  @override
  String get rateInvalid => 'Enter a rate greater than 0';

  @override
  String get fieldCurrentDebt => 'Current debt';

  @override
  String get fieldOpeningBalance => 'Opening balance';

  @override
  String get fieldCreditLimit => 'Credit limit';

  @override
  String get fieldStatementDay => 'Statement day (day of month)';

  @override
  String get fieldDueDay => 'Due day (day of month)';

  @override
  String get fieldCardLast4 => 'Last 4 digits of the card number';

  @override
  String get errorDayRange => 'Enter 1 to 31';

  @override
  String get errorNumber => 'Enter a number';

  @override
  String get errorLast4 => 'Enter 4 digits';

  @override
  String get transfer => 'Transfer';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get calculatorTooltip => 'Calculator';

  @override
  String get newTransaction => 'New transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get deleteTransactionTitle => 'Delete this transaction?';

  @override
  String get deleteCannotUndo => 'This can\'t be undone.';

  @override
  String get addAccountFirst => 'Add an account first';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldAccount => 'Account';

  @override
  String get fieldFromAccount => 'From account';

  @override
  String get fieldToAccount => 'To account';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldNoteOptional => 'Note (optional)';

  @override
  String get errorAmountPositive => 'Enter an amount greater than 0';

  @override
  String errorMissingRate(String entry, String account) {
    return '$entry or $account has no exchange rate yet. Set it on the Exchange rates tab first.';
  }

  @override
  String get errorConvertedTooSmall => 'The converted amount is too small';

  @override
  String get errorSelectAccount => 'Select an account';

  @override
  String get errorSelectToAccount => 'Select the account to transfer to';

  @override
  String get errorSameAccount => 'You can\'t transfer to the same account';

  @override
  String get errorSelectCategory => 'Select a category';

  @override
  String get fieldEntryCurrency => 'Entry currency (optional)';

  @override
  String entryCurrencySameAs(String currency) {
    return 'Same as the account ($currency)';
  }

  @override
  String get entryCurrencyNoRate =>
      'No exchange rate yet, so it can\'t be converted';

  @override
  String entryCurrencyConverted(String amount) {
    return 'Converts to $amount in the account';
  }

  @override
  String get entryCurrencyHint =>
      'Only needed when paying in another currency. It is converted to the account\'s currency at the current rate.';

  @override
  String fieldReceivedAmount(String currency) {
    return 'Amount received ($currency)';
  }

  @override
  String get receivedAmountNoRate =>
      'The exchange rates for these two currencies are not set. Enter the amount that was actually received.';

  @override
  String receivedAmountEstimate(String amount) {
    return 'About $amount at the current rate. Leave it empty to use this amount.';
  }

  @override
  String get errorReceivedPositive =>
      'The amount received must be greater than 0';

  @override
  String get errorReceivedRequired => 'Enter the amount received';

  @override
  String formatDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodSixMonths => 'Last 6 months';

  @override
  String get periodYear => 'Year';

  @override
  String get periodPreviousSixMonths => 'the previous six months';

  @override
  String get periodLastYear => 'last year';

  @override
  String get tooltipGoBack => 'Go back';

  @override
  String get tooltipGoForward => 'Go forward';

  @override
  String formatYear(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.y(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String formatYearMonth(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String formatMonthName(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String formatMonthShort(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String dateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get averageMonthlyExpense => 'Average monthly expense';

  @override
  String get averageMonthlyIncome => 'Average monthly income';

  @override
  String get monthlyIncomeExpense => 'Monthly income and expenses';

  @override
  String comparisonTitleMonth(String month) {
    return 'Compared with last month ($month)';
  }

  @override
  String comparisonTitleSixMonths(String range) {
    return 'Compared with the previous six months ($range)';
  }

  @override
  String comparisonTitleYear(String year) {
    return 'Compared with last year ($year)';
  }

  @override
  String comparisonNoRecords(String previous) {
    return 'There are no records for $previous, so there is nothing to compare.';
  }

  @override
  String get categoriesExpenseSection => 'Expense categories';

  @override
  String get categoriesIncomeSection => 'Income categories';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get fieldCategoryName => 'Category name';

  @override
  String get chooseIcon => 'Choose an icon';

  @override
  String get errorDuplicateCategory =>
      'A category with this name already exists';

  @override
  String get cannotDeleteTitle => 'Can\'t delete';

  @override
  String categoryInUse(int txCount, int ruleCount) {
    String _temp0 = intl.Intl.pluralLogic(
      txCount,
      locale: localeName,
      other: '$txCount transactions',
      one: '1 transaction',
    );
    String _temp1 = intl.Intl.pluralLogic(
      ruleCount,
      locale: localeName,
      other: '$ruleCount recurring rules',
      one: '1 recurring rule',
    );
    return 'This category is used by $_temp0 and $_temp1.\nTo change its name or icon, edit it instead.';
  }

  @override
  String get gotIt => 'Got it';

  @override
  String get deleteCategoryTitle => 'Delete this category?';

  @override
  String get recurringEmpty =>
      'No recurring items yet.\nFor example, monthly rent or salary: set it up once and it is recorded automatically.';

  @override
  String recurringDay(int day) {
    return 'Day $day of each month';
  }

  @override
  String get recurringPaused => 'Paused';

  @override
  String get newRecurring => 'New recurring item';

  @override
  String get editRecurring => 'Edit recurring item';

  @override
  String get deleteRecurringTitle => 'Delete this recurring item?';

  @override
  String get deleteRecurringMessage =>
      'No more transactions will be created automatically. The ones already created are kept.';

  @override
  String get fieldDayOfMonth => 'Day of the month';

  @override
  String get dayOfMonthHint =>
      'If a month does not have that day (for example February 31), the last day of the month is used.';

  @override
  String dayNumber(int day) {
    return 'Day $day';
  }

  @override
  String get fieldStartDate => 'Start date';

  @override
  String get errorRecurringCurrency =>
      'Recurring transfers don\'t support accounts with different currencies yet';

  @override
  String get ratesExplanation =>
      'The total balance and statistics are converted to Hong Kong dollars (HKD).\nRates marked Automatic update by themselves. A rate you change is marked Manual and is never overwritten. Changing a rate also changes the HKD value of past foreign-currency transactions.';

  @override
  String get rateStatusUpdating => 'Updating…';

  @override
  String rateStatusFailed(String reason) {
    return 'Last update failed: $reason';
  }

  @override
  String get rateStatusJustUpdated => 'Just updated';

  @override
  String get rateStatusIdle =>
      'The app updates the rates when needed (at most once or twice a day).';

  @override
  String get updateNow => 'Update now';

  @override
  String get ratesUpdated => 'Exchange rates updated';

  @override
  String get ratesUpdateFailed => 'Update failed';

  @override
  String rateSourceCredit(String name) {
    return 'Exchange rate data: $name';
  }

  @override
  String get rateManualHint =>
      'Once saved, it is marked Manual and is no longer updated automatically.';

  @override
  String get switchToAutomatic => 'Switch back to automatic updates';

  @override
  String get switchedToAutomatic => 'Switched back to automatic updates';

  @override
  String switchedToAutomaticFailed(String reason) {
    return 'Switched back to automatic updates, but this update failed: $reason';
  }

  @override
  String get rateNotSetInUse => 'No exchange rate set (an account is using it)';

  @override
  String get rateModeManual => 'Manual';

  @override
  String get rateModeAutomatic => 'Automatic';

  @override
  String rateUpdatedAt(String mode, DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$mode · updated $dateString $timeString';
  }

  @override
  String get inUse => 'In use';

  @override
  String rateErrorUnavailable(int code) {
    return 'The exchange rate service is unavailable right now ($code)';
  }

  @override
  String get rateErrorTimeout =>
      'The connection timed out. Check your network and try again.';

  @override
  String get rateErrorOffline => 'Can\'t connect. Check your network.';

  @override
  String get rateErrorSecure =>
      'Couldn\'t establish a secure connection. Check your network.';

  @override
  String get rateErrorBadFormat =>
      'The exchange rate data is in an unexpected format.';

  @override
  String get rateErrorService => 'The exchange rate service returned an error.';

  @override
  String get rateErrorUnknown =>
      'Something went wrong while updating the exchange rates.';

  @override
  String get notificationChannelName => 'Credit card payment reminders';

  @override
  String get notificationTitle => 'Credit card payment reminder';

  @override
  String notificationDueSoon(String card, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$card is due on $dateString. Remember to have the funds ready.';
  }

  @override
  String notificationDueToday(String card) {
    return 'Today is the payment due date for $card.';
  }
}
