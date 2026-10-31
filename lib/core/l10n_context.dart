import 'package:flutter/widgets.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';

/// Shorthand for the generated translations: `context.l10n.settings`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
