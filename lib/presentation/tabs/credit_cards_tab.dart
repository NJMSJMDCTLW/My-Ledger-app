import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/credit_card_section.dart';

/// The credit cards tab: debt, available credit, statement day and due day.
class CreditCardsTab extends ConsumerWidget {
  const CreditCardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final cards =
        accounts.where((a) => a.type == AccountType.creditCard).toList();
    final balances = ref.watch(balancesProvider);

    if (cards.isEmpty) {
      return Center(child: Text(context.l10n.creditCardsEmpty));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        CreditCardSection(cards: cards, balances: balances),
      ],
    );
  }
}
