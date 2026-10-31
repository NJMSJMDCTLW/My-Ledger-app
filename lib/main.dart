import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/notification_service.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderSyncProvider); // keep the due-date reminders in sync with the account data
    ref.watch(recurringSyncProvider); // on startup, create any recurring transactions that are due
    ref.watch(rateStartupSyncProvider); // update foreign-currency exchange rates automatically when needed

    return MaterialApp(
      title: '我的記帳本',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
