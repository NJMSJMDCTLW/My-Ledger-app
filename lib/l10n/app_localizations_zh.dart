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

  @override
  String get transfer => '轉帳';

  @override
  String get delete => '刪除';

  @override
  String get done => '完成';

  @override
  String get calculatorTooltip => '計算機';

  @override
  String get newTransaction => '新增交易';

  @override
  String get editTransaction => '編輯交易';

  @override
  String get deleteTransactionTitle => '刪除這筆交易？';

  @override
  String get deleteCannotUndo => '刪除後無法復原。';

  @override
  String get addAccountFirst => '請先新增一個帳戶';

  @override
  String get fieldAmount => '金額';

  @override
  String get fieldAccount => '帳戶';

  @override
  String get fieldFromAccount => '轉出帳戶';

  @override
  String get fieldToAccount => '轉入帳戶';

  @override
  String get fieldCategory => '類別';

  @override
  String get fieldDate => '日期';

  @override
  String get fieldNoteOptional => '備註（選填）';

  @override
  String get errorAmountPositive => '請輸入大於 0 的金額';

  @override
  String errorMissingRate(String entry, String account) {
    return '$entry 或 $account 還沒設定匯率，請先到「匯率」設定';
  }

  @override
  String get errorConvertedTooSmall => '換算後金額太小';

  @override
  String get errorSelectAccount => '請選擇帳戶';

  @override
  String get errorSelectToAccount => '請選擇轉入帳戶';

  @override
  String get errorSameAccount => '不能轉給同一個帳戶';

  @override
  String get errorSelectCategory => '請選擇類別';

  @override
  String get fieldEntryCurrency => '輸入貨幣（選填）';

  @override
  String entryCurrencySameAs(String currency) {
    return '與帳戶相同（$currency）';
  }

  @override
  String get entryCurrencyNoRate => '尚未設定匯率，無法換算';

  @override
  String entryCurrencyConverted(String amount) {
    return '折合 $amount，記在帳戶裡';
  }

  @override
  String get entryCurrencyHint => '用別的貨幣付款時才需要選，會依匯率換成帳戶的貨幣';

  @override
  String fieldReceivedAmount(String currency) {
    return '轉入金額（$currency）';
  }

  @override
  String get receivedAmountNoRate => '兩種貨幣的匯率還沒設定好，請自己填實際收到的金額';

  @override
  String receivedAmountEstimate(String amount) {
    return '依目前匯率約 $amount，留空就用這個金額';
  }

  @override
  String get errorReceivedPositive => '轉入金額要大於 0';

  @override
  String get errorReceivedRequired => '請填轉入金額';

  @override
  String formatDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get periodMonthly => '每月';

  @override
  String get periodSixMonths => '近六個月';

  @override
  String get periodYear => '一年';

  @override
  String get periodPreviousSixMonths => '前六個月';

  @override
  String get periodLastYear => '去年';

  @override
  String get tooltipGoBack => '往前';

  @override
  String get tooltipGoForward => '往後';

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
  String get averageMonthlyExpense => '平均每月支出';

  @override
  String get averageMonthlyIncome => '平均每月收入';

  @override
  String get monthlyIncomeExpense => '每月收支';

  @override
  String comparisonTitleMonth(String month) {
    return '與上個月比較（$month）';
  }

  @override
  String comparisonTitleSixMonths(String range) {
    return '與前六個月比較（$range）';
  }

  @override
  String comparisonTitleYear(String year) {
    return '與去年比較（$year）';
  }

  @override
  String comparisonNoRecords(String previous) {
    return '$previous沒有紀錄，無法比較';
  }

  @override
  String get categoriesExpenseSection => '支出分類';

  @override
  String get categoriesIncomeSection => '收入分類';

  @override
  String get newCategory => '新增分類';

  @override
  String get editCategory => '編輯分類';

  @override
  String get fieldCategoryName => '分類名稱';

  @override
  String get chooseIcon => '選一個圖示';

  @override
  String get errorDuplicateCategory => '已經有同名的分類';

  @override
  String get cannotDeleteTitle => '無法刪除';

  @override
  String categoryInUse(int txCount, int ruleCount) {
    return '這個分類已經被 $txCount 筆交易、$ruleCount 個固定收支使用。\n如果只是想換名字或圖示，可以直接編輯。';
  }

  @override
  String get gotIt => '知道了';

  @override
  String get deleteCategoryTitle => '刪除這個分類？';

  @override
  String get recurringEmpty => '還沒有固定收支\n例如每月的房租、薪水，設定一次就會自動記帳';

  @override
  String recurringDay(int day) {
    return '每月 $day 號';
  }

  @override
  String get recurringPaused => '已暫停';

  @override
  String get newRecurring => '新增固定收支';

  @override
  String get editRecurring => '編輯固定收支';

  @override
  String get deleteRecurringTitle => '刪除這個固定收支？';

  @override
  String get deleteRecurringMessage => '以後不會再自動新增。已經產生的交易會保留。';

  @override
  String get fieldDayOfMonth => '每月幾號';

  @override
  String get dayOfMonthHint => '該月沒有這一天（例如 2 月 31 號）會改在月底';

  @override
  String dayNumber(int day) {
    return '$day 號';
  }

  @override
  String get fieldStartDate => '開始日期';

  @override
  String get errorRecurringCurrency => '固定轉帳暫不支援不同貨幣的帳戶';

  @override
  String get ratesExplanation =>
      '總資產與統計都會折合成港幣（HKD）。\n標示「自動」的匯率會自動更新；自己修改過的會標示「手動」，不會被蓋掉。改了匯率之後，過去的外幣交易折合的港幣金額也會一起改變。';

  @override
  String get rateStatusUpdating => '更新中…';

  @override
  String rateStatusFailed(String reason) {
    return '上次更新失敗：$reason';
  }

  @override
  String get rateStatusJustUpdated => '剛剛已更新';

  @override
  String get rateStatusIdle => '需要時 App 會自動更新（每天最多一兩次）';

  @override
  String get updateNow => '立即更新';

  @override
  String get ratesUpdated => '匯率已更新';

  @override
  String get ratesUpdateFailed => '更新失敗';

  @override
  String rateSourceCredit(String name) {
    return '匯率資料來源：$name';
  }

  @override
  String get rateManualHint => '儲存後會標示為「手動」，不再自動更新';

  @override
  String get switchToAutomatic => '改回自動更新';

  @override
  String get switchedToAutomatic => '已改回自動更新';

  @override
  String switchedToAutomaticFailed(String reason) {
    return '已改回自動更新，但這次更新失敗：$reason';
  }

  @override
  String get rateNotSetInUse => '尚未設定匯率（有帳戶在使用）';

  @override
  String get rateModeManual => '手動';

  @override
  String get rateModeAutomatic => '自動';

  @override
  String rateUpdatedAt(String mode, DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$mode　更新於 $dateString $timeString';
  }

  @override
  String get inUse => '使用中';

  @override
  String rateErrorUnavailable(int code) {
    return '匯率服務暫時無法使用（$code）';
  }

  @override
  String get rateErrorTimeout => '連線逾時，請確認網路後再試';

  @override
  String get rateErrorOffline => '無法連線，請確認網路';

  @override
  String get rateErrorSecure => '無法建立安全連線，請確認網路';

  @override
  String get rateErrorBadFormat => '匯率資料格式不正確';

  @override
  String get rateErrorService => '匯率服務回傳錯誤';

  @override
  String get rateErrorUnknown => '更新匯率時發生錯誤';

  @override
  String get notificationChannelName => '信用卡繳款提醒';

  @override
  String get notificationTitle => '信用卡繳款提醒';

  @override
  String notificationDueSoon(String card, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$card 將於 $dateString 繳款，記得準備資金';
  }

  @override
  String notificationDueToday(String card) {
    return '今天是 $card 的繳款日';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String dayHeader(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String monthTitle(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String nextStatement(DateTime date, String when) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '下次結帳：$dateString（$when）';
  }

  @override
  String nextPayment(DateTime date, String when) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '下次繳款：$dateString（$when）';
  }

  @override
  String formatDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

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
  String rateUpdatedAt(String mode, DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$mode　更新於 $dateString $timeString';
  }

  @override
  String notificationDueSoon(String card, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$card 將於 $dateString 繳款，記得準備資金';
  }
}
