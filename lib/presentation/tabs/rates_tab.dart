import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:intl/intl.dart';

/// 匯率分頁：設定 1 單位外幣等於多少港幣，用來把外幣帳戶折合成港幣。
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
    final theme = Theme.of(context);

    // 使用中的外幣排前面，其餘照原本順序
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '總資產與統計都會折合成港幣（HKD）。\n'
              '匯率需要自己更新，App 不會自動上網抓。'
              '改了匯率之後，過去的外幣交易折合的港幣金額也會一起改變。',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        for (final c in foreign)
          _RateTile(
            currency: c,
            rate: rates[c.code],
            inUse: inUse.contains(c.code),
          ),
      ],
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
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        String? error;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('${currency.code} ${currency.name}'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '1 ${currency.code} = ? HKD',
                errorText: error,
              ),
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
    if (value == null) return;

    final db = ref.read(databaseProvider);
    await db.into(db.exchangeRates).insertOnConflictUpdate(
          ExchangeRatesCompanion.insert(
            currency: currency.code,
            rateToHkd: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// 去掉多餘的 0，例如 7.8000 -> 7.8
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
              : '1 ${currency.code} = ${_plain(rate!.rateToHkd)} HKD'
                  '　更新於 ${DateFormat('yyyy/MM/dd').format(rate!.updatedAt)}',
          style: missing && inUse
              ? TextStyle(color: theme.colorScheme.error)
              : null,
        ),
        trailing: inUse ? const Chip(label: Text('使用中')) : null,
      ),
    );
  }
}
