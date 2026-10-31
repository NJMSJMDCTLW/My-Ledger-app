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

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get archive => '封存';

  @override
  String get unarchive => '取消封存';

  @override
  String get accountTypeBank => '銀行帳戶';

  @override
  String get accountTypeCash => '現金';

  @override
  String get accountTypeCreditCard => '信用卡';

  @override
  String get accountTypeEWallet => '電子錢包';

  @override
  String get currencyNameHKD => '港幣';

  @override
  String get currencyNameUSD => '美元';

  @override
  String get currencyNameCNY => '人民幣';

  @override
  String get currencyNameTWD => '新台幣';

  @override
  String get currencyNameJPY => '日圓';

  @override
  String get currencyNameKRW => '韓圜';

  @override
  String get currencyNameEUR => '歐元';

  @override
  String get currencyNameGBP => '英鎊';

  @override
  String get currencyNameSGD => '新加坡幣';

  @override
  String get currencyNameAUD => '澳幣';

  @override
  String get currencyNameCAD => '加幣';

  @override
  String get currencyNameTHB => '泰銖';

  @override
  String get accountsEmpty => '還沒有帳戶，點右下角新增';

  @override
  String get archivedAccounts => '已封存帳戶';

  @override
  String get rateNotSet => '尚未設定匯率';

  @override
  String get creditCardsEmpty => '還沒有信用卡，點右下角新增';

  @override
  String creditDebt(String amount) {
    return '欠款 $amount';
  }

  @override
  String creditAvailable(String available, String limit) {
    return '可用額度 $available / $limit';
  }

  @override
  String get statementDayNotSet => '結帳日：未設定';

  @override
  String nextStatement(DateTime date, String when) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '下次結帳：$dateString（$when）';
  }

  @override
  String get dueDayNotSet => '繳款日：未設定';

  @override
  String nextPayment(DateTime date, String when) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '下次繳款：$dateString（$when）';
  }

  @override
  String get payReminder => '⚠ 記得繳款';

  @override
  String daysFromNow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天後',
      one: '明天',
      zero: '今天',
    );
    return '$_temp0';
  }

  @override
  String get addAccount => '新增帳戶';

  @override
  String get editAccount => '編輯帳戶';

  @override
  String get archiveAccountTitle => '封存這個帳戶？';

  @override
  String get archiveAccountMessage =>
      '封存後不會出現在帳戶清單與總資產，也不能再選來記帳。歷史交易會保留，隨時可以取消封存。';

  @override
  String get fieldName => '名稱';

  @override
  String get nameRequired => '請輸入名稱';

  @override
  String get fieldAccountType => '類型';

  @override
  String get fieldCurrency => '貨幣';

  @override
  String get currencyLockedHint => '已有紀錄的帳戶不能更換貨幣';

  @override
  String rateFieldLabel(String currency) {
    return '匯率：1 $currency = ? HKD';
  }

  @override
  String get rateFetching => '正在自動取得最新匯率…';

  @override
  String get rateFetchFailedHint => '自動取得失敗，可以按右邊的按鈕重試，或自己填寫。之後可以在「匯率」分頁修改';

  @override
  String get rateFetchTooltip => '自動取得最新匯率';

  @override
  String get rateInvalid => '請輸入大於 0 的匯率';

  @override
  String get fieldCurrentDebt => '目前欠款';

  @override
  String get fieldOpeningBalance => '期初餘額';

  @override
  String get fieldCreditLimit => '信用額度';

  @override
  String get fieldStatementDay => '結帳日（每月幾號）';

  @override
  String get fieldDueDay => '繳款日（每月幾號）';

  @override
  String get fieldCardLast4 => '卡號末四碼';

  @override
  String get errorDayRange => '請輸入 1~31';

  @override
  String get errorNumber => '請輸入數字';

  @override
  String get errorLast4 => '請輸入 4 碼';
}
