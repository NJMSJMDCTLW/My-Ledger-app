import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:intl/intl.dart';

/// Add or edit a recurring rule.
class RecurringFormPage extends ConsumerStatefulWidget {
  const RecurringFormPage({super.key, this.existing});

  /// Non-null means editing this rule; null means adding a new one.
  final RecurringRule? existing;

  @override
  ConsumerState<RecurringFormPage> createState() => _RecurringFormPageState();
}

class _RecurringFormPageState extends ConsumerState<RecurringFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _startDate = DateTime.now();
  int _day = DateTime.now().day;
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;

  bool get _isEditing => widget.existing != null;

  String _currencyOf(int? accountId) {
    if (accountId == null) return baseCurrency;
    return ref.read(hkdConverterProvider).currencyOfAccount(accountId);
  }
  bool get _isTransfer => _type == TransactionType.transfer;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _type = r.type;
      _startDate = r.startDate;
      _day = r.dayOfMonth;
      _accountId = r.accountId;
      _toAccountId = r.toAccountId;
      _categoryId = r.categoryId;
      _amount.text = (r.amount / 100).toStringAsFixed(2);
      _note.text = r.note;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);

    final companion = RecurringRulesCompanion(
      type: Value(_type),
      amount: Value(parseCents(_amount.text)!),
      accountId: Value(_accountId!),
      toAccountId: Value(_isTransfer ? _toAccountId : null),
      categoryId: Value(_isTransfer ? null : _categoryId),
      note: Value(_note.text.trim()),
      dayOfMonth: Value(_day),
      startDate: Value(_startDate),
    );

    if (_isEditing) {
      final id = widget.existing!.id;
      await (db.update(db.recurringRules)..where((r) => r.id.equals(id)))
          .write(companion);
    } else {
      await db.into(db.recurringRules).insert(companion);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除這個固定收支？'),
        content: const Text('以後不會再自動新增。已經產生的交易會保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final db = ref.read(databaseProvider);
    final id = widget.existing!.id;
    await (db.delete(db.recurringRules)..where((r) => r.id.equals(id))).go();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.existing;
    // When editing, show the account even if the rule's account has been archived
    final accounts = (ref.watch(allAccountsProvider).value ?? [])
        .where((a) =>
            !a.isArchived || a.id == ex?.accountId || a.id == ex?.toAccountId)
        .toList();
    final allCategories = ref.watch(categoriesProvider).value ?? [];

    final categoryType = _type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final categories =
        allCategories.where((c) => c.type == categoryType).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '編輯固定收支' : '新增固定收支'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: '刪除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: accounts.isEmpty
          ? const Center(child: Text('請先新增一個帳戶'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<TransactionType>(
                    segments: [
                      for (final t in TransactionType.values)
                        ButtonSegment(value: t, label: Text(t.label)),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() {
                      _type = s.first;
                      _categoryId = null; // income and expense have different categories, so clear it when switching
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amount,
                    decoration: InputDecoration(
                      labelText: '金額',
                      prefixText: currencyInfo(_currencyOf(_accountId)).symbol,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: !_isEditing,
                    validator: (v) {
                      final cents = parseCents(v ?? '');
                      return (cents == null || cents <= 0)
                          ? '請輸入大於 0 的金額'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _day,
                    decoration: const InputDecoration(
                      labelText: '每月幾號',
                      helperText: '該月沒有這一天（例如 2 月 31 號）會改在月底',
                    ),
                    items: [
                      for (var d = 1; d <= 31; d++)
                        DropdownMenuItem(value: d, child: Text('$d 號')),
                    ],
                    onChanged: (v) => setState(() => _day = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _accountId,
                    decoration: InputDecoration(
                      labelText: _isTransfer ? '轉出帳戶' : '帳戶',
                    ),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _accountId = v),
                    validator: (v) => v == null ? '請選擇帳戶' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_isTransfer)
                    DropdownButtonFormField<int>(
                      initialValue: _toAccountId,
                      decoration: const InputDecoration(labelText: '轉入帳戶'),
                      items: [
                        for (final a in accounts)
                          DropdownMenuItem(value: a.id, child: Text(a.name)),
                      ],
                      onChanged: (v) => setState(() => _toAccountId = v),
                      validator: (v) {
                        if (v == null) return '請選擇轉入帳戶';
                        if (v == _accountId) return '不能轉給同一個帳戶';
                        // A recurring transfer is recorded automatically every month and cannot ask how much was actually received each time, so only same-currency accounts are supported
                        if (_currencyOf(v) != _currencyOf(_accountId)) {
                          return '固定轉帳暫不支援不同貨幣的帳戶';
                        }
                        return null;
                      },
                    )
                  else
                    DropdownButtonFormField<int>(
                      key: ValueKey(categoryType), // rebuild when the type changes to clear the old choice
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: '類別'),
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(categoryIcon(c), size: 20),
                                const SizedBox(width: 12),
                                Text(c.name),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) => v == null ? '請選擇類別' : null,
                    ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('開始日期'),
                    subtitle: Text(DateFormat('yyyy/MM/dd').format(_startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickStartDate,
                  ),
                  TextFormField(
                    controller: _note,
                    decoration: const InputDecoration(labelText: '備註（選填）'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _save, child: const Text('儲存')),
                ],
              ),
            ),
    );
  }
}
