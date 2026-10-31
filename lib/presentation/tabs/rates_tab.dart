import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/rate_service.dart';
import 'package:intl/intl.dart';

/// The rates tab: exchange rates used to convert foreign currencies to HKD. They update automatically by default, or you can enter one yourself (and it will not be overwritten by automatic updates).
class RatesTab extends ConsumerWidget {
  const RatesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = {
      for (final r in ref.watch(exchangeRatesProvider).value ?? [])
        r.currency: r,
    };
    final accounts = ref.watch(accountsProvider).value ?? [];
    final inUse = {for (final a in accounts) a.currency};

    // Currencies in use come first; the rest keep their original order
    final foreign = supportedCurrencies
        .where((c) => c.code != baseCurrency)
        .toList()
      ..sort((a, b) {
        final ua = inUse.contains(a.code) ? 0 : 1;
        final ub = inUse.contains(b.code) ? 0 : 1;
        return ua.compareTo(ub);
      });

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        const _UpdateCard(),
        for (final c in foreign)
          _RateTile(
            currency: c,
            rate: rates[c.code],
            inUse: inUse.contains(c.code),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text(
            '匯率資料來源：$rateSourceName',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// The card at the top: explanation, the update-now button, and the update status.
class _UpdateCard extends ConsumerWidget {
  const _UpdateCard();

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(rateUpdaterProvider.notifier).refresh();
    if (!context.mounted) return;
    final error = ref.read(rateUpdaterProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '匯率已更新' : (error ?? '更新失敗'))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(rateUpdaterProvider);
    final theme = Theme.of(context);

    final String statusText;
    if (status.isLoading) {
      statusText = '更新中…';
    } else if (status.error != null) {
      statusText = '上次更新失敗：${status.error}';
    } else if (status.lastSuccess != null) {
      statusText = '剛剛已更新';
    } else {
      statusText = '需要時 App 會自動更新（每天最多一兩次）';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '總資產與統計都會折合成港幣（HKD）。\n'
              '標示「自動」的匯率會自動更新；自己修改過的會標示「手動」，不會被蓋掉。'
              '改了匯率之後，過去的外幣交易折合的港幣金額也會一起改變。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    statusText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: status.error != null
                          ? theme.colorScheme.error
                          : theme.hintColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed:
                      status.isLoading ? null : () => _refresh(context, ref),
                  icon: status.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('立即更新'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RateTile extends ConsumerWidget {
  const _RateTile({
    required this.currency,
    required this.rate,
    required this.inUse,
  });

  final CurrencyInfo currency;
  final ExchangeRate? rate;
  final bool inUse;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: rate == null ? '' : _plain(rate!.rateToHkd),
    );
    // Returns a double to set this rate manually; null means cancelled;
    // -1 means "switch back to automatic"
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        String? error;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('${currency.code} ${currency.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '1 ${currency.code} = ? HKD',
                    helperText: '儲存後會標示為「手動」，不再自動更新',
                    errorText: error,
                  ),
                ),
                if (rate?.isManual ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context, -1),
                      icon: const Icon(Icons.autorenew),
                      label: const Text('改回自動更新'),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final v = double.tryParse(controller.text.trim());
                  if (v == null || v <= 0) {
                    setState(() => error = '請輸入大於 0 的數字');
                    return;
                  }
                  Navigator.pop(context, v);
                },
                child: const Text('儲存'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (result == null) return;

    final db = ref.read(databaseProvider);
    if (result == -1) {
      await useAutomaticRate(db, currency.code);
      final ok = await ref.read(rateUpdaterProvider.notifier).refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '已改回自動更新'
            : '已改回自動更新，但這次更新失敗：${ref.read(rateUpdaterProvider).error ?? ''}'),
      ));
    } else {
      await setManualRate(db, currency.code, result);
    }
  }

  /// Removes trailing zeros, e.g. 7.8000 -> 7.8
  static String _plain(double v) {
    final s = v.toStringAsFixed(6);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final missing = rate == null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: missing && inUse
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        onTap: () => _edit(context, ref),
        leading: CircleAvatar(
          child: Text(currency.symbol, style: const TextStyle(fontSize: 12)),
        ),
        title: Text('${currency.code}　${currency.name}'),
        subtitle: Text(
          missing
              ? (inUse ? '尚未設定匯率（有帳戶在使用）' : '尚未設定')
              : '1 ${currency.code} = ${_plain(rate!.rateToHkd)} HKD\n'
                  '${rate!.isManual ? '手動' : '自動'}'
                  '　更新於 ${DateFormat('yyyy/MM/dd HH:mm').format(rate!.updatedAt)}',
          style: missing && inUse
              ? TextStyle(color: theme.colorScheme.error)
              : null,
        ),
        isThreeLine: !missing,
        trailing: inUse ? const Chip(label: Text('使用中')) : null,
      ),
    );
  }
}
