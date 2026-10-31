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
