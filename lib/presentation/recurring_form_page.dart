import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';

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
        title: Text(context.l10n.deleteRecurringTitle),
        content: Text(context.l10n.deleteRecurringMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
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
        title: Text(_isEditing ? context.l10n.editRecurring : context.l10n.newRecurring),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: context.l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: accounts.isEmpty
          ? Center(child: Text(context.l10n.addAccountFirst))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<TransactionType>(
                    segments: [
                      for (final t in TransactionType.values)
                        ButtonSegment(value: t, label: Text(t.label(context.l10n))),
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
                      labelText: context.l10n.fieldAmount,
                      prefixText: currencyInfo(_currencyOf(_accountId)).symbol,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: !_isEditing,
                    validator: (v) {
                      final cents = parseCents(v ?? '');
                      return (cents == null || cents <= 0)
                          ? context.l10n.errorAmountPositive
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _day,
                    decoration: InputDecoration(
                      labelText: context.l10n.fieldDayOfMonth,
                      helperText: context.l10n.dayOfMonthHint,
                    ),
                    items: [
                      for (var d = 1; d <= 31; d++)
                        DropdownMenuItem(
                          value: d,
                          child: Text(context.l10n.dayNumber(d)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _day = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _accountId,
                    decoration: InputDecoration(
                      labelText: _isTransfer ? context.l10n.fieldFromAccount : context.l10n.fieldAccount,
                    ),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _accountId = v),
                    validator: (v) => v == null ? context.l10n.errorSelectAccount : null,
                  ),
                  const SizedBox(height: 16),
                  if (_isTransfer)
                    DropdownButtonFormField<int>(
                      initialValue: _toAccountId,
                      decoration: InputDecoration(labelText: context.l10n.fieldToAccount),
                      items: [
                        for (final a in accounts)
                          DropdownMenuItem(value: a.id, child: Text(a.name)),
                      ],
                      onChanged: (v) => setState(() => _toAccountId = v),
                      validator: (v) {
                        if (v == null) return context.l10n.errorSelectToAccount;
                        if (v == _accountId) return context.l10n.errorSameAccount;
                        // A recurring transfer is recorded automatically every month and cannot ask how much was actually received each time, so only same-currency accounts are supported
                        if (_currencyOf(v) != _currencyOf(_accountId)) {
                          return context.l10n.errorRecurringCurrency;
                        }
                        return null;
                      },
                    )
                  else
                    DropdownButtonFormField<int>(
                      key: ValueKey(categoryType), // rebuild when the type changes to clear the old choice
                      initialValue: _categoryId,
                      decoration: InputDecoration(labelText: context.l10n.fieldCategory),
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
                      validator: (v) => v == null ? context.l10n.errorSelectCategory : null,
                    ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.fieldStartDate),
                    subtitle: Text(context.l10n.formatDate(_startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickStartDate,
                  ),
                  TextFormField(
                    controller: _note,
                    decoration: InputDecoration(labelText: context.l10n.fieldNoteOptional),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _save, child: Text(context.l10n.save)),
                ],
              ),
            ),
    );
  }
}
