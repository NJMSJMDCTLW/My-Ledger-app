import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's small key-value settings store. It must be loaded before the app starts, so
/// `main` creates it and overrides this provider (see `main.dart`).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

/// The language the user picked, saved on the phone so it survives restarts.
class AppLanguageNotifier extends Notifier<AppLanguage> {
  static const storageKey = 'app_language';

  @override
  AppLanguage build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(storageKey);
    return appLanguageFromStorage(saved);
  }

  Future<void> select(AppLanguage language) async {
    state = language;
    await ref
        .read(sharedPreferencesProvider)
        .setString(storageKey, language.name);
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(AppLanguageNotifier.new);
