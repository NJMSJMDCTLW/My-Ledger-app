import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:intl/intl.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key});

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

    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            date: _date,
            amount: parseCents(_amount.text)!,
            type: _type,
            accountId: _accountId!,
            toAccountId: Value(_isTransfer ? _toAccountId : null),
            categoryId: Value(_isTransfer ? null : _categoryId),
            note: Value(_note.text.trim()),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final allCategories = ref.watch(categoriesProvider).value ?? [];

    final categoryType = _type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final categories =
        allCategories.where((c) => c.type == categoryType).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('新增交易')),
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
                    autofocus: true,
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
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
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
