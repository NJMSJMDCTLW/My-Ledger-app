import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/account_form_page.dart';
import 'package:hello_ledger/presentation/widgets/account_icon.dart';

/// The accounts tab: all accounts with their balances, plus archived accounts.
class AccountsTab extends ConsumerWidget {
  const AccountsTab({super.key});

  void _edit(BuildContext context, Account a) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => AccountFormPage(existing: a)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAccounts = ref.watch(allAccountsProvider).value ?? [];
    final accounts = allAccounts.where((a) => !a.isArchived).toList();
    final archived = allAccounts.where((a) => a.isArchived).toList();
    final balances = ref.watch(balancesProvider);
    final converter = ref.watch(hkdConverterProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        Card(
          child: accounts.isEmpty
              ? ListTile(title: Text(context.l10n.accountsEmpty))
              : Column(
                  children: [
                    for (final a in accounts)
                      ListTile(
                        onTap: () => _edit(context, a),
                        leading: AccountIcon(a.type),
                        title: Text(a.name),
                        subtitle: Text(a.currency == baseCurrency
                            ? a.type.label(context.l10n)
                            : '${a.type.label(context.l10n)} · ${a.currency}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoney(balances[a.id] ?? 0, a.currency),
                              style: theme.textTheme.titleSmall,
                            ),
                            // for a foreign-currency account, also show the HKD equivalent
                            if (a.currency != baseCurrency)
                              Text(
                                converter.hasRate(a.currency)
                                    ? '≈ ${formatMoney(converter.toHkd(balances[a.id] ?? 0, a.currency), baseCurrency)}'
                                    : context.l10n.rateNotSet,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: converter.hasRate(a.currency)
                                      ? null
                                      : theme.colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (archived.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 4),
            child: Text(context.l10n.archivedAccounts, style: theme.textTheme.titleMedium),
          ),
          Card(
            child: Column(
              children: [
                for (final a in archived)
                  ListTile(
                    onTap: () => _edit(context, a),
                    leading: AccountIcon(a.type),
                    title: Text(a.name),
                    subtitle: Text(a.type.label(context.l10n)),
                    textColor: theme.disabledColor,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
