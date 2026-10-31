// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '我的記帳本';

  @override
  String get settings => '設定';

  @override
  String get language => '語言';

  @override
  String get languageFollowSystem => '跟隨系統';

  @override
  String get languageFollowSystemHint => '手機設為中文時使用繁體中文，其他語言則使用英文。';

  @override
  String get navHome => '首頁';

  @override
  String get navStatistics => '統計';

  @override
  String get navAccounts => '帳戶';

  @override
  String get navCreditCards => '信用卡';

  @override
  String get navRecurring => '固定收支';

  @override
  String get navCategories => '分類管理';

  @override
  String get navRates => '匯率';

  @override
  String get fabAddTransaction => '記一筆';

  @override
  String get fabAddAccount => '新增帳戶';

  @override
  String get fabAddCreditCard => '新增信用卡';

  @override
  String get fabAddRecurring => '新增固定收支';

  @override
  String get fabAddCategory => '新增分類';

  @override
  String get totalBalance => '總資產';

  @override
  String get expenseCategories => '支出類別';

  @override
  String get viewStatisticsTooltip => '查看詳細統計';

  @override
  String get transactionsHeading => '交易紀錄';

  @override
  String get noTransactionsThisMonth => '這個月還沒有交易';

  @override
  String transferTitle(String from, String to) {
    return '轉帳：$from → $to';
  }

  @override
  String get uncategorized => '未分類';

  @override
  String balanceAmount(String amount) {
    return '結餘 $amount';
  }

  @override
  String dayHeader(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get tooltipPreviousMonth => '上個月';

  @override
  String get tooltipNextMonth => '下個月';

  @override
  String monthTitle(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get balance => '結餘';

  @override
  String get noExpensesThisMonth => '這個月沒有支出';

  @override
  String get totalExpense => '總支出';

  @override
  String get comparisonNew => '新增';

  @override
  String originalAmount(String amount) {
    return '原幣 $amount';
  }

  @override
  String get listSeparator => '、';

  @override
  String ratesMissingWarning(String currencies) {
    return '$currencies 還沒設定匯率，折合港幣的金額不完整。請到側邊欄「匯率」設定。';
  }

  @override
  String get ratesConvertedNote => '外幣已依「匯率」分頁的設定折合成港幣（HKD）。';

  @override
  String get periodLastMonth => '上月';

  @override
  String comparisonSame(String previous) {
    return '與$previous持平';
  }

  @override
  String comparisonNoData(String previous) {
    return '$previous無資料';
  }
}
