import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_language.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/data/settings_providers.dart';

/// The settings tab. For now it only holds the language setting.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
          child: Text(context.l10n.language, style: theme.textTheme.titleMedium),
        ),
        Card(
          child: RadioGroup<AppLanguage>(
            groupValue: current,
            onChanged: (language) {
              if (language != null) {
                ref.read(appLanguageProvider.notifier).select(language);
              }
            },
            child: Column(
              children: [
                RadioListTile<AppLanguage>(
                  value: AppLanguage.system,
                  title: Text(context.l10n.languageFollowSystem),
                  subtitle: Text(context.l10n.languageFollowSystemHint),
                ),
                // A language is always named in its own language, so these two are not translated.
                const RadioListTile<AppLanguage>(
                  value: AppLanguage.traditionalChinese,
                  title: Text('繁體中文'),
                ),
                const RadioListTile<AppLanguage>(
                  value: AppLanguage.english,
                  title: Text('English'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
