import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/data/rate_service.dart';

class AccountFormPage extends ConsumerStatefulWidget {
  const AccountFormPage({super.key, this.existing, this.initialType});

  /// Default account type when adding (e.g. coming from the credit card tab selects credit card).
  final AccountType? initialType;

  /// Non-null means editing this account; null means adding a new one.
  final Account? existing;

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _balance = TextEditingController();
  final _limit = TextEditingController();
  final _statementDay = TextEditingController();
  final _dueDay = TextEditingController();
  final _last4 = TextEditingController();
  final _rate = TextEditingController();
  AccountType _type = AccountType.bank;
  String _currency = baseCurrency;

  bool get _isCredit => _type == AccountType.creditCard;
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _type = widget.initialType ?? AccountType.bank;
    if (a != null) {
      _name.text = a.name;
      _type = a.type;
      _currency = a.currency;
      // A credit card's debt is stored as a negative number; show it as positive when editing
      _balance.text = (a.openingBalance.abs() / 100).toStringAsFixed(2);
      if (a.creditLimit != null) {
        _limit.text = (a.creditLimit! / 100).toStringAsFixed(2);
      }
      _statementDay.text = a.statementDay?.toString() ?? '';
      _dueDay.text = a.dueDay?.toString() ?? '';
      _last4.text = a.last4 ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _balance,
      _limit,
      _statementDay,
      _dueDay,
      _last4,
      _rate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateDay(String? v) {
    if (v == null || v.isEmpty) return null;
    final n = int.tryParse(v);
    if (n == null || n < 1 || n > 31) return '請輸入 1~31';
    return null;
  }

  String? _validateMoney(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return parseCents(v) == null ? '請輸入數字' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);

    var opening = parseCents(_balance.text) ?? 0;
    // A credit card's debt is stored as a negative number, so the "debt" the user typed is turned negative
    if (_isCredit) opening = -opening.abs();

    final companion = AccountsCompanion(
      name: Value(_name.text.trim()),
      type: Value(_type),
      currency: Value(_currency),
      openingBalance: Value(opening),
      creditLimit: Value(_isCredit ? parseCents(_limit.text) : null),
      statementDay: Value(_isCredit ? int.tryParse(_statementDay.text) : null),
      dueDay: Value(_isCredit ? int.tryParse(_dueDay.text) : null),
      last4: Value(_isCredit && _last4.text.isNotEmpty ? _last4.text : null),
    );

    // First use of this foreign currency: save the rate the user entered (editable later on the "Rates" tab)
    final rate = double.tryParse(_rate.text.trim());
    if (_needsRate && rate != null) {
      // Entered by the user, so mark it manual; automatic updates will not overwrite it
      await setManualRate(db, _currency, rate);
    }

    if (_isEditing) {
      final id = widget.existing!.id;
      await (db.update(db.accounts)..where((a) => a.id.equals(id)))
          .write(companion);
    } else {
      await db.into(db.accounts).insert(companion);
    }
    if (mounted) Navigator.pop(context);
  }

  /// When adding a foreign-currency account whose currency has no rate yet, the user has to enter one.
  bool get _needsRate =>
      !_isEditing &&
      _currency != baseCurrency &&
      !ref.read(hkdConverterProvider).hasRate(_currency);

  Future<void> _toggleArchive() async {
    final account = widget.existing!;
    final archiving = !account.isArchived;

    if (archiving) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('封存這個帳戶？'),
          content: const Text('封存後不會出現在帳戶清單與總資產，也不能再選來記帳。'
              '歷史交易會保留，隨時可以取消封存。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('封存'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    final db = ref.read(databaseProvider);
    await (db.update(db.accounts)..where((a) => a.id.equals(account.id)))
        .write(AccountsCompanion(isArchived: Value(archiving)));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '編輯帳戶' : '新增帳戶'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: widget.existing!.isArchived ? '取消封存' : '封存',
              icon: Icon(widget.existing!.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined),
              onPressed: _toggleArchive,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '名稱'),
              maxLength: 50,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '請輸入名稱' : null,
            ),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '類型'),
              items: [
                for (final t in AccountType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(
                labelText: '貨幣',
                helperText: _isEditing ? '已有紀錄的帳戶不能更換貨幣' : null,
              ),
              items: [
                for (final c in supportedCurrencies)
                  DropdownMenuItem(
                    value: c.code,
                    child: Text('${c.code}　${c.name}'),
                  ),
              ],
              // The currency cannot change when editing, or old amounts would be read as another currency
              onChanged: _isEditing
                  ? null
                  : (v) {
                      setState(() => _currency = v!);
                      // If this currency has no rate yet, try fetching it automatically first; ask the user only if that fails
                      if (_needsRate) {
                        ref.read(rateUpdaterProvider.notifier).refresh();
                      }
                    },
            ),
            if (!_isEditing &&
                _currency != baseCurrency &&
                !ref.watch(hkdConverterProvider).hasRate(_currency)) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _rate,
                decoration: InputDecoration(
                  labelText: '匯率：1 $_currency = ? HKD',
                  helperText: ref.watch(rateUpdaterProvider).isLoading
                      ? '正在自動取得最新匯率…'
                      : '自動取得失敗，可以按右邊的按鈕重試，或自己填寫。之後可以在「匯率」分頁修改',
                  suffixIcon: IconButton(
                    tooltip: '自動取得最新匯率',
                    icon: const Icon(Icons.cloud_download_outlined),
                    onPressed: ref.watch(rateUpdaterProvider).isLoading
                        ? null
                        : () => ref
                            .read(rateUpdaterProvider.notifier)
                            .refresh(),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final r = double.tryParse(v?.trim() ?? '');
                  return (r == null || r <= 0) ? '請輸入大於 0 的匯率' : null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _balance,
              decoration: InputDecoration(
                labelText: _isCredit ? '目前欠款' : '期初餘額',
                prefixText: currencyInfo(_currency).symbol,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validateMoney,
            ),
            if (_isCredit) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _limit,
                decoration: InputDecoration(
                  labelText: '信用額度',
                  prefixText: currencyInfo(_currency).symbol,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validateMoney,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _statementDay,
                decoration: const InputDecoration(labelText: '結帳日（每月幾號）'),
                keyboardType: TextInputType.number,
                validator: _validateDay,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueDay,
                decoration: const InputDecoration(labelText: '繳款日（每月幾號）'),
                keyboardType: TextInputType.number,
                validator: _validateDay,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _last4,
                decoration: const InputDecoration(labelText: '卡號末四碼'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (v) => (v != null && v.isNotEmpty && v.length != 4)
                    ? '請輸入 4 碼'
                    : null,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('儲存')),
          ],
        ),
      ),
    );
  }
}
