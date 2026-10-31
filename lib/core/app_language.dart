import 'package:flutter/widgets.dart';

/// The locale used for Traditional Chinese (Taiwan). The translations live in `app_zh.arb`;
/// using zh_TW as the app locale makes dates and numbers follow Taiwan conventions.
const traditionalChineseLocale = Locale('zh', 'TW');

const englishLocale = Locale('en');

/// What the user chose in the language setting.
enum AppLanguage { system, traditionalChinese, english }

extension AppLanguageLocale on AppLanguage {
  /// The locale to force, or null to follow the phone's language.
  Locale? get locale => switch (this) {
        AppLanguage.system => null,
        AppLanguage.traditionalChinese => traditionalChineseLocale,
        AppLanguage.english => englishLocale,
      };
}

/// Reads a saved value back into an [AppLanguage]. Anything unknown (or nothing saved yet)
/// means "follow the system".
AppLanguage appLanguageFromStorage(String? value) {
  return AppLanguage.values.firstWhere(
    (language) => language.name == value,
    orElse: () => AppLanguage.system,
  );
}

/// Picks the app language from the phone's preferred languages (most preferred first):
/// the first one that is Chinese or English wins, and any Chinese becomes Traditional
/// Chinese because that is the only Chinese translation. Falls back to English.
Locale resolveSystemLocale(List<Locale>? deviceLocales) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'zh') return traditionalChineseLocale;
    if (locale.languageCode == 'en') return englishLocale;
  }
  return englishLocale;
}
