# My Ledger

**English** | [繁體中文](README.zh-TW.md)

A personal bookkeeping app that **keeps all of its data on your own phone**, built with Flutter
and currently targeting Android. There is no sign-up and nothing is uploaded to a server.

> The app's interface is currently in Traditional Chinese (繁體中文). English support, with a
> language setting, is in progress.

## Features

**Recording**
- Income, expense, and transfer transactions, with edit and delete.
- Built-in calculator for entering amounts (`+ − × ÷`).
- Notes are remembered and offered as one-tap suggestions the next time you pick the same category.
- Transactions are grouped by day, with each day's balance.

**Accounts and credit cards**
- Four account types: bank, cash, credit card, and e-wallet. Accounts can be archived.
- Credit cards track a limit, statement day, and due day, and show the debt and available credit.
- Push notifications 3 days before the due date and on the due date at 9:00.

**Categories**
- Add, rename, and delete categories, choosing an icon from a recommended list.
- Every category keeps the same color throughout the app.

**Recurring transactions**
- Set up fixed monthly income or expenses (such as rent). Due transactions are created
  automatically when the app starts, and months you missed are filled in all at once.

**Statistics**
- Monthly, last six months, and yearly views.
- Expense pie chart, monthly income/expense bar chart, and a per-category breakdown.
- Comparison with the previous period (last month, the previous six months, or last year).

**Multiple currencies**
- 12 currencies. Each account has its own currency, and the total balance and statistics are
  always converted to Hong Kong dollars (HKD).
- Exchange rates update automatically, or you can set one by hand. A manual rate is never
  overwritten by an automatic update.
- When you pay in a different currency, you can pick the input currency; the amount is converted
  to the account's currency and the original amount is kept.
- For transfers between currencies you can enter the amount that was actually received.

## Privacy

- All of your data is stored in a local SQLite database on the phone and is **never uploaded**.
- The only network request the app makes is for exchange rates: one `GET` request to
  `open.er-api.com` that carries no personal or bookkeeping data (the server only sees your IP
  address). It happens only when you have a foreign-currency account or press the manual update
  button.
- No ads, no analytics, no accounts.

## Known limitations

- There is no export or backup feature yet, so the data lives only on the phone.
- Exchange rates are not kept as history: changing a rate also changes the HKD value of past
  foreign-currency transactions. (A transaction entered in a different currency is converted once,
  at the time it is recorded, and that amount stays fixed.)
- Credit card due-date notifications show the card name and last four digits, which is visible
  on the lock screen.
- Android's default auto-backup is not disabled, so the database may be backed up to your
  Google account.
- Only tested on Android.
- This is a personal learning project. Release builds still use the debug signing key and are not
  ready to be published to an app store.

## Tech stack

| Purpose | Package |
| --- | --- |
| Framework | Flutter (Dart ^3.13) |
| State management | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| Local database | [drift](https://pub.dev/packages/drift) + SQLite |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Notifications | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) |

Project layout:

```
lib/
├── core/           # UI-independent helpers: calculator, money formatting, currencies, dates, theme
├── data/           # Tables, database, Riverpod providers, exchange-rate and recurring logic
└── presentation/   # Screens: drawer tabs, form pages, shared widgets
test/               # Unit tests: calculator, statistics, rates, recurring, database migrations
```

## Getting started

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) and an Android
development environment.

```bash
# Install packages
flutter pub get

# Generate the Drift database code (run it again after editing lib/data/tables.dart)
dart run build_runner build

# Run on a phone (USB debugging on) or an emulator
flutter run

# Static analysis and tests
flutter analyze
flutter test
```

On Windows, if you see `Building with plugins requires symlink support`, turn on Developer Mode
under Settings → System → For developers.

## Data source

Exchange rates come from [ExchangeRate-API](https://www.exchangerate-api.com) (free open endpoint).

## License

No license has been chosen yet. Until a LICENSE file is added, all rights are reserved.
