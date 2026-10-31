# 我的記帳本 (My Ledger)

[English](README.md) | **繁體中文**

一個**只存在自己手機裡**的個人記帳 App，用 Flutter 開發，目前以 Android 為主。
記帳資料全部存在手機本機，不需要註冊帳號，也不會上傳到任何伺服器。

> 目前 App 介面只有繁體中文。英文介面與語言設定正在開發中。

## 功能

**記帳**
- 收入、支出、轉帳三種交易，可編輯與刪除。
- 內建計算機輸入金額，支援 `+ − × ÷`。
- 備註會被記下來，下次選同一個類別時當作推薦清單，點一下就能重複使用。
- 交易依日期分組，並顯示當天結餘。

**帳戶與信用卡**
- 銀行、現金、信用卡、電子錢包四種帳戶，可封存。
- 信用卡可設定額度、結帳日、繳款日，顯示欠款與可用額度。
- 繳款日前 3 天與當天早上 9 點發出手機通知。

**分類**
- 自行新增、改名、刪除分類，從推薦清單挑選圖示。
- 每個分類在整個 App 裡有固定的顏色。

**固定收支**
- 設定每月固定的收入、支出（例如房租），App 啟動時會自動補上到期的交易，
  很久沒開 App 也會一次補齊。

**統計**
- 每月、近六個月、一年三種範圍。
- 支出圓餅圖、每月收支長條圖、各類別明細。
- 和上一期（上個月、前六個月、去年）比較。

**多貨幣**
- 支援 12 種貨幣，每個帳戶有自己的貨幣，總資產與統計一律折合成港幣（HKD）。
- 匯率可自動更新，也可以手動指定（手動的不會被自動更新蓋掉）。
- 用別的貨幣付款時，記帳可以選輸入貨幣，依匯率換成帳戶的貨幣並保留原始金額。
- 跨貨幣轉帳可以填實際收到的金額。

## 隱私

- 所有記帳資料存在手機本機的 SQLite 資料庫，**不會上傳**。
- App 唯一會連網路的地方是更新匯率：對 `open.er-api.com` 發出一個不帶任何個人或記帳資料的
  GET 請求（對方只會看到你的 IP）。只有在你有外幣帳戶、或手動按「立即更新」時才會連網。
- 沒有廣告、沒有分析追蹤、沒有帳號系統。

## 已知限制

- 目前沒有資料匯出與備份功能，資料只存在手機裡。
- 匯率不記錄歷史：改了匯率後，過去外幣交易折合的港幣金額也會跟著變。
  （用別的貨幣輸入的交易，換算後的金額在記帳當下就固定了。）
- 信用卡繳款通知會顯示卡名與末四碼，鎖定畫面上看得到。
- Android 預設的自動備份沒有關閉，資料庫可能被備份到 Google 帳戶。
- 只在 Android 上測試過。
- 目前是個人學習專案，發行版本還沿用除錯簽章，不適合直接上架。

## 技術

| 用途 | 套件 |
| --- | --- |
| 框架 | Flutter (Dart ^3.13) |
| 狀態管理 | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| 本機資料庫 | [drift](https://pub.dev/packages/drift) + SQLite |
| 圖表 | [fl_chart](https://pub.dev/packages/fl_chart) |
| 通知 | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) |

程式碼結構：

```
lib/
├── core/           # 與畫面無關的工具：計算機、金額格式、貨幣、日期、主題
├── data/           # 資料表、資料庫、Riverpod providers、匯率與固定收支邏輯
└── presentation/   # 畫面：側邊欄分頁 (tabs)、表單頁、共用元件 (widgets)
test/               # 單元測試：計算機、統計、匯率、固定收支、資料庫升級
```

## 開始使用

需要先安裝 [Flutter SDK](https://docs.flutter.dev/get-started/install) 與 Android 開發環境。

```bash
# 安裝套件
flutter pub get

# 產生 Drift 的資料庫程式碼（修改 lib/data/tables.dart 後也要重跑）
dart run build_runner build

# 接上手機（開啟 USB 偵錯）或啟動模擬器後執行
flutter run

# 靜態檢查與測試
flutter analyze
flutter test
```

在 Windows 上，如果出現 `Building with plugins requires symlink support`，
請到「設定 → 系統 → 開發人員專用」開啟開發人員模式。

## 資料來源

匯率資料來自 [ExchangeRate-API](https://www.exchangerate-api.com)（免費公開端點）。

## 授權

尚未決定授權條款。在加上 LICENSE 檔案之前，保留所有權利。
