import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/core/notification_service.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/settings_providers.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:hello_ledger/presentation/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  // Load the saved settings first, so the app starts in the right language with no flicker.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderSyncProvider); // keep the due-date reminders in sync with the account data
    ref.watch(recurringSyncProvider); // on startup, create any recurring transactions that are due
    ref.watch(rateStartupSyncProvider); // update foreign-currency exchange rates automatically when needed

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // null follows the phone's language (see localeListResolutionCallback below)
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (locales, supported) =>
          resolveSystemLocale(locales),
      home: const AppShell(),
    );
  }
}
