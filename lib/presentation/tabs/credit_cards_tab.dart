import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/credit_card_section.dart';

/// 信用卡分頁：欠款、可用額度、結帳日與繳款日。
class CreditCardsTab extends ConsumerWidget {
  const CreditCardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final cards =
        accounts.where((a) => a.type == AccountType.creditCard).toList();
    final balances = ref.watch(balancesProvider);

    if (cards.isEmpty) {
      return const Center(child: Text('還沒有信用卡，點右下角新增'));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        CreditCardSection(cards: cards, balances: balances),
      ],
    );
  }
}
