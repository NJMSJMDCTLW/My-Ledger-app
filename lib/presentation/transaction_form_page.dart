import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:intl/intl.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.existing});

  /// 有值代表編輯這筆交易；null 代表新增。
  final TransactionRecord? existing;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _type = t.type;
      _date = t.date;
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      _categoryId = t.categoryId;
      _amount.text = (t.amount / 100).toStringAsFixed(2);
      _note.text = t.note;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _isTransfer => _type == TransactionType.transfer;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);

    final companion = TransactionsCompanion(
      date: Value(_date),
      amount: Value(parseCents(_amount.text)!),
      type: Value(_type),
      accountId: Value(_accountId!),
      toAccountId: Value(_isTransfer ? _toAccountId : null),
      categoryId: Value(_isTransfer ? null : _categoryId),
      note: Value(_note.text.trim()),
    );

    if (_isEditing) {
      final id = widget.existing!.id;
      await (db.update(db.transactions)..where((t) => t.id.equals(id)))
          .write(companion);
    } else {
      await db.into(db.transactions).insert(companion);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除這筆交易？'),
        content: const Text('刪除後無法復原。'),
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
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 編輯舊交易時，即使它用的帳戶已封存也要能顯示
    final ex = widget.existing;
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
        title: Text(_isEditing ? '編輯交易' : '新增交易'),
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
                      _categoryId = null; // 收入/支出的類別不同，切換時清掉
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amount,
                    decoration: const InputDecoration(labelText: '金額'),
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
                        return null;
                      },
                    )
                  else
                    DropdownButtonFormField<int>(
                      key: ValueKey(categoryType), // 類型改變時重建，清掉舊選項
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('日期'),
                    subtitle: Text(DateFormat('yyyy/MM/dd').format(_date)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
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
