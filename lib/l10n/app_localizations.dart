import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// The name of the app, shown in the app bar and the navigation drawer.
  ///
  /// In en, this message translates to:
  /// **'My Ledger'**
  String get appTitle;

  /// Title of the settings tab and its entry in the navigation drawer.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Heading of the language section in the settings tab.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language option that uses the phone's language.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageFollowSystem;

  /// Explains how the Follow system language option picks a language.
  ///
  /// In en, this message translates to:
  /// **'Uses Traditional Chinese when the phone is set to Chinese, and English otherwise.'**
  String get languageFollowSystemHint;

  /// Navigation drawer entry for the home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navCreditCards.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get navCreditCards;

  /// Navigation drawer entry for fixed income and expenses that repeat every month, such as rent.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get navRecurring;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get navRates;

  /// No description provided for @fabAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get fabAddTransaction;

  /// No description provided for @fabAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get fabAddAccount;

  /// No description provided for @fabAddCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Add credit card'**
  String get fabAddCreditCard;

  /// No description provided for @fabAddRecurring.
  ///
  /// In en, this message translates to:
  /// **'Add recurring'**
  String get fabAddRecurring;

  /// No description provided for @fabAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get fabAddCategory;

  /// Heading of the card showing the sum of all accounts, converted to HKD.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get expenseCategories;

  /// No description provided for @viewStatisticsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View detailed statistics'**
  String get viewStatisticsTooltip;

  /// No description provided for @transactionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsHeading;

  /// No description provided for @noTransactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get noTransactionsThisMonth;

  /// Title of a transfer transaction. The placeholders are the names of the two accounts.
  ///
  /// In en, this message translates to:
  /// **'Transfer: {from} → {to}'**
  String transferTitle(String from, String to);

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// A day's balance (income minus expense) in the home tab.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String balanceAmount(String amount);

  /// The heading above each day's transactions: the date with the weekday.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String dayHeader(DateTime date);

  /// No description provided for @tooltipPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get tooltipPreviousMonth;

  /// No description provided for @tooltipNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get tooltipNextMonth;

  /// The month shown between the previous and next buttons, e.g. October 2026.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String monthTitle(DateTime date);

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month'**
  String get noExpensesThisMonth;

  /// No description provided for @totalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total expense'**
  String get totalExpense;

  /// Shown next to a category that had no spending in the previous period but has some now.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get comparisonNew;

  /// The amount the user originally typed when paying in a different currency than the account's.
  ///
  /// In en, this message translates to:
  /// **'Original {amount}'**
  String originalAmount(String amount);

  /// Separator used when joining several items into one sentence.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @ratesMissingWarning.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate is set for {currencies}, so the HKD amounts are incomplete. Set it under Exchange rates in the drawer.'**
  String ratesMissingWarning(String currencies);

  /// No description provided for @ratesConvertedNote.
  ///
  /// In en, this message translates to:
  /// **'Foreign currencies are converted to HKD using the rates on the Exchange rates tab.'**
  String get ratesConvertedNote;

  /// Name of the previous period when comparing a month with the one before it. Used inside sentences such as 'Same as last month'.
  ///
  /// In en, this message translates to:
  /// **'last month'**
  String get periodLastMonth;

  /// No description provided for @comparisonSame.
  ///
  /// In en, this message translates to:
  /// **'Same as {previous}'**
  String comparisonSame(String previous);

  /// No description provided for @comparisonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data for {previous}'**
  String comparisonNoData(String previous);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountTypeCreditCard;

  /// No description provided for @accountTypeEWallet.
  ///
  /// In en, this message translates to:
  /// **'E-wallet'**
  String get accountTypeEWallet;

  /// No description provided for @currencyNameHKD.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong dollar'**
  String get currencyNameHKD;

  /// No description provided for @currencyNameUSD.
  ///
  /// In en, this message translates to:
  /// **'US dollar'**
  String get currencyNameUSD;

  /// No description provided for @currencyNameCNY.
  ///
  /// In en, this message translates to:
  /// **'Chinese yuan'**
  String get currencyNameCNY;

  /// No description provided for @currencyNameTWD.
  ///
  /// In en, this message translates to:
  /// **'New Taiwan dollar'**
  String get currencyNameTWD;

  /// No description provided for @currencyNameJPY.
  ///
  /// In en, this message translates to:
  /// **'Japanese yen'**
  String get currencyNameJPY;

  /// No description provided for @currencyNameKRW.
  ///
  /// In en, this message translates to:
  /// **'South Korean won'**
  String get currencyNameKRW;

  /// No description provided for @currencyNameEUR.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyNameEUR;

  /// No description provided for @currencyNameGBP.
  ///
  /// In en, this message translates to:
  /// **'British pound'**
  String get currencyNameGBP;

  /// No description provided for @currencyNameSGD.
  ///
  /// In en, this message translates to:
  /// **'Singapore dollar'**
  String get currencyNameSGD;

  /// No description provided for @currencyNameAUD.
  ///
  /// In en, this message translates to:
  /// **'Australian dollar'**
  String get currencyNameAUD;

  /// No description provided for @currencyNameCAD.
  ///
  /// In en, this message translates to:
  /// **'Canadian dollar'**
  String get currencyNameCAD;

  /// No description provided for @currencyNameTHB.
  ///
  /// In en, this message translates to:
  /// **'Thai baht'**
  String get currencyNameTHB;

  /// No description provided for @accountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Tap the button at the bottom right to add one.'**
  String get accountsEmpty;

  /// No description provided for @archivedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Archived accounts'**
  String get archivedAccounts;

  /// No description provided for @rateNotSet.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate set'**
  String get rateNotSet;

  /// No description provided for @creditCardsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No credit cards yet. Tap the button at the bottom right to add one.'**
  String get creditCardsEmpty;

  /// No description provided for @creditDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt {amount}'**
  String creditDebt(String amount);

  /// Available credit on a credit card, out of its total limit.
  ///
  /// In en, this message translates to:
  /// **'Available {available} / {limit}'**
  String creditAvailable(String available, String limit);

  /// No description provided for @statementDayNotSet.
  ///
  /// In en, this message translates to:
  /// **'Statement day: not set'**
  String get statementDayNotSet;

  /// No description provided for @nextStatement.
  ///
  /// In en, this message translates to:
  /// **'Next statement: {date} ({when})'**
  String nextStatement(DateTime date, String when);

  /// No description provided for @dueDayNotSet.
  ///
  /// In en, this message translates to:
  /// **'Due day: not set'**
  String get dueDayNotSet;

  /// No description provided for @nextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment: {date} ({when})'**
  String nextPayment(DateTime date, String when);

  /// No description provided for @payReminder.
  ///
  /// In en, this message translates to:
  /// **'⚠ Remember to pay'**
  String get payReminder;

  /// How far away a date is, e.g. 'today', 'tomorrow', 'in 3 days'.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{today} =1{tomorrow} other{in {days} days}}'**
  String daysFromNow(int days);

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccount;

  /// No description provided for @archiveAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this account?'**
  String get archiveAccountTitle;

  /// No description provided for @archiveAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Once archived, it no longer appears in the account list or the total balance, and it can\'t be picked when recording. Past transactions are kept, and you can unarchive it at any time.'**
  String get archiveAccountMessage;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameRequired;

  /// No description provided for @fieldAccountType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldAccountType;

  /// No description provided for @fieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// No description provided for @currencyLockedHint.
  ///
  /// In en, this message translates to:
  /// **'An account that already has records can\'t change its currency.'**
  String get currencyLockedHint;

  /// No description provided for @rateFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate: 1 {currency} = ? HKD'**
  String rateFieldLabel(String currency);

  /// No description provided for @rateFetching.
  ///
  /// In en, this message translates to:
  /// **'Getting the latest rate automatically…'**
  String get rateFetching;

  /// No description provided for @rateFetchFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get it automatically. Tap the button on the right to retry, or enter it yourself. You can change it later on the Exchange rates tab.'**
  String get rateFetchFailedHint;

  /// No description provided for @rateFetchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Get the latest rate automatically'**
  String get rateFetchTooltip;

  /// No description provided for @rateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate greater than 0'**
  String get rateInvalid;

  /// No description provided for @fieldCurrentDebt.
  ///
  /// In en, this message translates to:
  /// **'Current debt'**
  String get fieldCurrentDebt;

  /// No description provided for @fieldOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get fieldOpeningBalance;

  /// No description provided for @fieldCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get fieldCreditLimit;

  /// No description provided for @fieldStatementDay.
  ///
  /// In en, this message translates to:
  /// **'Statement day (day of month)'**
  String get fieldStatementDay;

  /// No description provided for @fieldDueDay.
  ///
  /// In en, this message translates to:
  /// **'Due day (day of month)'**
  String get fieldDueDay;

  /// No description provided for @fieldCardLast4.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits of the card number'**
  String get fieldCardLast4;

  /// No description provided for @errorDayRange.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 31'**
  String get errorDayRange;

  /// No description provided for @errorNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get errorNumber;

  /// No description provided for @errorLast4.
  ///
  /// In en, this message translates to:
  /// **'Enter 4 digits'**
  String get errorLast4;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @calculatorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculatorTooltip;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get newTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteCannotUndo;

  /// No description provided for @addAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an account first'**
  String get addAccountFirst;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get fieldAccount;

  /// No description provided for @fieldFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get fieldFromAccount;

  /// No description provided for @fieldToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get fieldToAccount;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// No description provided for @fieldNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get fieldNoteOptional;

  /// No description provided for @errorAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0'**
  String get errorAmountPositive;

  /// Shown when an amount cannot be converted because a currency has no exchange rate. The placeholders are currency codes.
  ///
  /// In en, this message translates to:
  /// **'{entry} or {account} has no exchange rate yet. Set it on the Exchange rates tab first.'**
  String errorMissingRate(String entry, String account);

  /// No description provided for @errorConvertedTooSmall.
  ///
  /// In en, this message translates to:
  /// **'The converted amount is too small'**
  String get errorConvertedTooSmall;

  /// No description provided for @errorSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get errorSelectAccount;

  /// No description provided for @errorSelectToAccount.
  ///
  /// In en, this message translates to:
  /// **'Select the account to transfer to'**
  String get errorSelectToAccount;

  /// No description provided for @errorSameAccount.
  ///
  /// In en, this message translates to:
  /// **'You can\'t transfer to the same account'**
  String get errorSameAccount;

  /// No description provided for @errorSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get errorSelectCategory;

  /// No description provided for @fieldEntryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Entry currency (optional)'**
  String get fieldEntryCurrency;

  /// No description provided for @entryCurrencySameAs.
  ///
  /// In en, this message translates to:
  /// **'Same as the account ({currency})'**
  String entryCurrencySameAs(String currency);

  /// No description provided for @entryCurrencyNoRate.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate yet, so it can\'t be converted'**
  String get entryCurrencyNoRate;

  /// No description provided for @entryCurrencyConverted.
  ///
  /// In en, this message translates to:
  /// **'Converts to {amount} in the account'**
  String entryCurrencyConverted(String amount);

  /// No description provided for @entryCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Only needed when paying in another currency. It is converted to the account\'s currency at the current rate.'**
  String get entryCurrencyHint;

  /// No description provided for @fieldReceivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount received ({currency})'**
  String fieldReceivedAmount(String currency);

  /// No description provided for @receivedAmountNoRate.
  ///
  /// In en, this message translates to:
  /// **'The exchange rates for these two currencies are not set. Enter the amount that was actually received.'**
  String get receivedAmountNoRate;

  /// No description provided for @receivedAmountEstimate.
  ///
  /// In en, this message translates to:
  /// **'About {amount} at the current rate. Leave it empty to use this amount.'**
  String receivedAmountEstimate(String amount);

  /// No description provided for @errorReceivedPositive.
  ///
  /// In en, this message translates to:
  /// **'The amount received must be greater than 0'**
  String get errorReceivedPositive;

  /// No description provided for @errorReceivedRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount received'**
  String get errorReceivedRequired;

  /// A full date in the locale's short numeric format, e.g. 10/31/2026 or 2026/10/31.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String formatDate(DateTime date);

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @periodSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get periodSixMonths;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// Name of the previous period when comparing six months with the six before. Used inside sentences such as 'Same as the previous six months'.
  ///
  /// In en, this message translates to:
  /// **'the previous six months'**
  String get periodPreviousSixMonths;

  /// No description provided for @periodLastYear.
  ///
  /// In en, this message translates to:
  /// **'last year'**
  String get periodLastYear;

  /// No description provided for @tooltipGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get tooltipGoBack;

  /// No description provided for @tooltipGoForward.
  ///
  /// In en, this message translates to:
  /// **'Go forward'**
  String get tooltipGoForward;

  /// A year, e.g. 2026.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String formatYear(DateTime date);

  /// A month with its year in short numeric form, e.g. 5/2026 or 2026/5.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String formatYearMonth(DateTime date);

  /// The name of a month, e.g. September.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String formatMonthName(DateTime date);

  /// A short month label for the bar chart, e.g. Oct.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String formatMonthShort(DateTime date);

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String dateRange(String start, String end);

  /// No description provided for @averageMonthlyExpense.
  ///
  /// In en, this message translates to:
  /// **'Average monthly expense'**
  String get averageMonthlyExpense;

  /// No description provided for @averageMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Average monthly income'**
  String get averageMonthlyIncome;

  /// No description provided for @monthlyIncomeExpense.
  ///
  /// In en, this message translates to:
  /// **'Monthly income and expenses'**
  String get monthlyIncomeExpense;

  /// No description provided for @comparisonTitleMonth.
  ///
  /// In en, this message translates to:
  /// **'Compared with last month ({month})'**
  String comparisonTitleMonth(String month);

  /// No description provided for @comparisonTitleSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Compared with the previous six months ({range})'**
  String comparisonTitleSixMonths(String range);

  /// No description provided for @comparisonTitleYear.
  ///
  /// In en, this message translates to:
  /// **'Compared with last year ({year})'**
  String comparisonTitleYear(String year);

  /// No description provided for @comparisonNoRecords.
  ///
  /// In en, this message translates to:
  /// **'There are no records for {previous}, so there is nothing to compare.'**
  String comparisonNoRecords(String previous);

  /// No description provided for @categoriesExpenseSection.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get categoriesExpenseSection;

  /// No description provided for @categoriesIncomeSection.
  ///
  /// In en, this message translates to:
  /// **'Income categories'**
  String get categoriesIncomeSection;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @fieldCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get fieldCategoryName;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an icon'**
  String get chooseIcon;

  /// No description provided for @errorDuplicateCategory.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists'**
  String get errorDuplicateCategory;

  /// No description provided for @cannotDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t delete'**
  String get cannotDeleteTitle;

  /// No description provided for @categoryInUse.
  ///
  /// In en, this message translates to:
  /// **'This category is used by {txCount, plural, =1{1 transaction} other{{txCount} transactions}} and {ruleCount, plural, =1{1 recurring rule} other{{ruleCount} recurring rules}}.\nTo change its name or icon, edit it instead.'**
  String categoryInUse(int txCount, int ruleCount);

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get deleteCategoryTitle;

  /// No description provided for @recurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring items yet.\nFor example, monthly rent or salary: set it up once and it is recorded automatically.'**
  String get recurringEmpty;

  /// No description provided for @recurringDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of each month'**
  String recurringDay(int day);

  /// No description provided for @recurringPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringPaused;

  /// No description provided for @newRecurring.
  ///
  /// In en, this message translates to:
  /// **'New recurring item'**
  String get newRecurring;

  /// No description provided for @editRecurring.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring item'**
  String get editRecurring;

  /// No description provided for @deleteRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this recurring item?'**
  String get deleteRecurringTitle;

  /// No description provided for @deleteRecurringMessage.
  ///
  /// In en, this message translates to:
  /// **'No more transactions will be created automatically. The ones already created are kept.'**
  String get deleteRecurringMessage;

  /// No description provided for @fieldDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get fieldDayOfMonth;

  /// No description provided for @dayOfMonthHint.
  ///
  /// In en, this message translates to:
  /// **'If a month does not have that day (for example February 31), the last day of the month is used.'**
  String get dayOfMonthHint;

  /// No description provided for @dayNumber.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dayNumber(int day);

  /// No description provided for @fieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get fieldStartDate;

  /// No description provided for @errorRecurringCurrency.
  ///
  /// In en, this message translates to:
  /// **'Recurring transfers don\'t support accounts with different currencies yet'**
  String get errorRecurringCurrency;

  /// No description provided for @ratesExplanation.
  ///
  /// In en, this message translates to:
  /// **'The total balance and statistics are converted to Hong Kong dollars (HKD).\nRates marked Automatic update by themselves. A rate you change is marked Manual and is never overwritten. Changing a rate also changes the HKD value of past foreign-currency transactions.'**
  String get ratesExplanation;

  /// No description provided for @rateStatusUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get rateStatusUpdating;

  /// No description provided for @rateStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Last update failed: {reason}'**
  String rateStatusFailed(String reason);

  /// No description provided for @rateStatusJustUpdated.
  ///
  /// In en, this message translates to:
  /// **'Just updated'**
  String get rateStatusJustUpdated;

  /// No description provided for @rateStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'The app updates the rates when needed (at most once or twice a day).'**
  String get rateStatusIdle;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @ratesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates updated'**
  String get ratesUpdated;

  /// No description provided for @ratesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get ratesUpdateFailed;

  /// No description provided for @rateSourceCredit.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate data: {name}'**
  String rateSourceCredit(String name);

  /// No description provided for @rateManualHint.
  ///
  /// In en, this message translates to:
  /// **'Once saved, it is marked Manual and is no longer updated automatically.'**
  String get rateManualHint;

  /// No description provided for @switchToAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Switch back to automatic updates'**
  String get switchToAutomatic;

  /// No description provided for @switchedToAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Switched back to automatic updates'**
  String get switchedToAutomatic;

  /// No description provided for @switchedToAutomaticFailed.
  ///
  /// In en, this message translates to:
  /// **'Switched back to automatic updates, but this update failed: {reason}'**
  String switchedToAutomaticFailed(String reason);

  /// No description provided for @rateNotSetInUse.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate set (an account is using it)'**
  String get rateNotSetInUse;

  /// No description provided for @rateModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get rateModeManual;

  /// No description provided for @rateModeAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get rateModeAutomatic;

  /// No description provided for @rateUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'{mode} · updated {date} {time}'**
  String rateUpdatedAt(String mode, DateTime date, DateTime time);

  /// No description provided for @inUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get inUse;

  /// No description provided for @rateErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The exchange rate service is unavailable right now ({code})'**
  String rateErrorUnavailable(int code);

  /// No description provided for @rateErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out. Check your network and try again.'**
  String get rateErrorTimeout;

  /// No description provided for @rateErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect. Check your network.'**
  String get rateErrorOffline;

  /// No description provided for @rateErrorSecure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t establish a secure connection. Check your network.'**
  String get rateErrorSecure;

  /// No description provided for @rateErrorBadFormat.
  ///
  /// In en, this message translates to:
  /// **'The exchange rate data is in an unexpected format.'**
  String get rateErrorBadFormat;

  /// No description provided for @rateErrorService.
  ///
  /// In en, this message translates to:
  /// **'The exchange rate service returned an error.'**
  String get rateErrorService;

  /// No description provided for @rateErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while updating the exchange rates.'**
  String get rateErrorUnknown;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Credit card payment reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit card payment reminder'**
  String get notificationTitle;

  /// No description provided for @notificationDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{card} is due on {date}. Remember to have the funds ready.'**
  String notificationDueSoon(String card, DateTime date);

  /// No description provided for @notificationDueToday.
  ///
  /// In en, this message translates to:
  /// **'Today is the payment due date for {card}.'**
  String notificationDueToday(String card);

  /// Name of a built-in category. The built-in category names follow the app language; categories the user creates keep the name they typed.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// No description provided for @categoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get categoryMedical;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryOtherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOtherExpense;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get categoryBonus;

  /// No description provided for @categoryOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOtherIncome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
