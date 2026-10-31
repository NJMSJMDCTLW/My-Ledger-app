import 'package:hello_ledger/l10n/app_localizations.dart';

/// The translated display name of a currency, e.g. 'USD' -> "US dollar" or "美元".
/// An unknown code (should not happen) is shown as the code itself.
String currencyName(AppLocalizations l10n, String code) {
  return switch (code) {
    'HKD' => l10n.currencyNameHKD,
    'USD' => l10n.currencyNameUSD,
    'CNY' => l10n.currencyNameCNY,
    'TWD' => l10n.currencyNameTWD,
    'JPY' => l10n.currencyNameJPY,
    'KRW' => l10n.currencyNameKRW,
    'EUR' => l10n.currencyNameEUR,
    'GBP' => l10n.currencyNameGBP,
    'SGD' => l10n.currencyNameSGD,
    'AUD' => l10n.currencyNameAUD,
    'CAD' => l10n.currencyNameCAD,
    'THB' => l10n.currencyNameTHB,
    _ => code,
  };
}
