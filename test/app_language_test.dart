import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ledger/core/app_language.dart';

void main() {
  group('appLanguageFromStorage', () {
    test('Reads back every saved value', () {
      for (final language in AppLanguage.values) {
        expect(appLanguageFromStorage(language.name), language);
      }
    });

    test('Nothing saved or an unknown value means follow the system', () {
      expect(appLanguageFromStorage(null), AppLanguage.system);
      expect(appLanguageFromStorage('klingon'), AppLanguage.system);
    });
  });

  group('AppLanguage.locale', () {
    test('Follow system has no forced locale', () {
      expect(AppLanguage.system.locale, isNull);
    });

    test('Traditional Chinese uses zh_TW and English uses en', () {
      expect(AppLanguage.traditionalChinese.locale, const Locale('zh', 'TW'));
      expect(AppLanguage.english.locale, const Locale('en'));
    });
  });

  group('resolveSystemLocale', () {
    test('Any Chinese becomes Traditional Chinese', () {
      for (final locale in const [
        Locale('zh'),
        Locale('zh', 'TW'),
        Locale('zh', 'HK'),
        Locale('zh', 'CN'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ]) {
        expect(resolveSystemLocale([locale]), const Locale('zh', 'TW'));
      }
    });

    test('English stays English', () {
      expect(resolveSystemLocale(const [Locale('en', 'US')]), const Locale('en'));
    });

    test('Uses the first supported language in the phone preference order', () {
      // Japanese is not supported, so the next preference (Chinese) wins
      expect(
        resolveSystemLocale(const [Locale('ja'), Locale('zh', 'TW'), Locale('en')]),
        const Locale('zh', 'TW'),
      );
      expect(
        resolveSystemLocale(const [Locale('en'), Locale('zh', 'TW')]),
        const Locale('en'),
      );
    });

    test('Falls back to English when nothing is supported or the list is empty', () {
      expect(resolveSystemLocale(const [Locale('ja'), Locale('fr')]), const Locale('en'));
      expect(resolveSystemLocale(const []), const Locale('en'));
      expect(resolveSystemLocale(null), const Locale('en'));
    });
  });
}
