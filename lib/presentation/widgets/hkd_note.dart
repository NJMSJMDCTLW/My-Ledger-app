import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/data/providers.dart';

/// When there are foreign-currency accounts, reminds that amounts are converted to HKD; if a foreign currency has no rate yet, it becomes a warning.
/// Shows nothing when all accounts are in HKD.
class HkdNote extends ConsumerWidget {
  const HkdNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final missing = ref.watch(missingRateCurrenciesProvider);
    final hasForeign = accounts.any((a) => a.currency != baseCurrency);
    if (!hasForeign) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isWarning = missing.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
            size: 16,
            color: isWarning ? theme.colorScheme.error : theme.hintColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isWarning
                  ? '${missing.join('、')} 還沒設定匯率，折合港幣的金額不完整。'
                      '請到側邊欄「匯率」設定。'
                  : '外幣已依「匯率」分頁的設定折合成港幣（HKD）。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isWarning ? theme.colorScheme.error : theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
