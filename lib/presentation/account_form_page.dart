import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';

class AccountFormPage extends ConsumerStatefulWidget {
  const AccountFormPage({super.key, this.existing});

  /// 有值代表編輯這個帳戶；null 代表新增。
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
  AccountType _type = AccountType.bank;

  bool get _isCredit => _type == AccountType.creditCard;
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    if (a != null) {
      _name.text = a.name;
      _type = a.type;
      // 信用卡的欠款存成負數，編輯時顯示成正數
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
    for (final c in [_name, _balance, _limit, _statementDay, _dueDay, _last4]) {
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
    // 信用卡的欠款用負數表示，所以使用者輸入「欠款」時轉成負數
    if (_isCredit) opening = -opening.abs();

    final companion = AccountsCompanion(
      name: Value(_name.text.trim()),
      type: Value(_type),
      openingBalance: Value(opening),
      creditLimit: Value(_isCredit ? parseCents(_limit.text) : null),
      statementDay: Value(_isCredit ? int.tryParse(_statementDay.text) : null),
      dueDay: Value(_isCredit ? int.tryParse(_dueDay.text) : null),
      last4: Value(_isCredit && _last4.text.isNotEmpty ? _last4.text : null),
    );

    if (_isEditing) {
      final id = widget.existing!.id;
      await (db.update(db.accounts)..where((a) => a.id.equals(id)))
          .write(companion);
    } else {
      await db.into(db.accounts).insert(companion);
    }
    if (mounted) Navigator.pop(context);
  }

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
            TextFormField(
              controller: _balance,
              decoration: InputDecoration(
                labelText: _isCredit ? '目前欠款' : '期初餘額',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validateMoney,
            ),
            if (_isCredit) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _limit,
                decoration: const InputDecoration(labelText: '信用額度'),
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
