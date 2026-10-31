import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/category_names.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/core/currency_names.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/core/entry_amount.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/core/note_suggestions.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/widgets/calculator_sheet.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.existing});

  /// Non-null means editing this transaction; null means adding a new one.
  final TransactionRecord? existing;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _toAmount = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;

  /// The input currency the user picked; null means the same as the account's currency (optional, null by default).
  String? _entryCurrency;

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
      // If it was originally entered in another currency, show the original amount and currency when editing
      if (t.originalAmount != null && t.originalCurrency != null) {
        _entryCurrency = t.originalCurrency;
        _amount.text = (t.originalAmount! / 100).toStringAsFixed(2);
      } else {
        _amount.text = (t.amount / 100).toStringAsFixed(2);
      }
      _note.text = t.note;
      if (t.toAmount != null) {
        _toAmount.text = (t.toAmount! / 100).toStringAsFixed(2);
      }
    } else {
      // New transaction: open the calculator right away so the amount can be typed immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final accounts = ref.read(accountsProvider).value ?? [];
        if (mounted && accounts.isNotEmpty) _openCalculator();
      });
    }
  }

  /// Opens the calculator and puts the result into [target] (the amount field by default).
  Future<void> _openCalculator([TextEditingController? target]) async {
    final controller = target ?? _amount;
    final result = await showCalculator(context, initial: controller.text);
    if (result != null) {
      setState(() => controller.text = result);
      _formKey.currentState?.validate();
    }
  }

  String _currencyOf(int? accountId) {
    if (accountId == null) return baseCurrency;
    return ref.read(hkdConverterProvider).currencyOfAccount(accountId);
  }

  /// The currency the amount was actually entered in: the chosen one if any, otherwise the account's currency. Transfers always use the account's currency.
  String get _entryCurrencyCode => _isTransfer
      ? _currencyOf(_accountId)
      : (_entryCurrency ?? _currencyOf(_accountId));

  /// The entry currency differs from the account's currency, so a conversion is needed.
  bool get _isConverting =>
      !_isTransfer &&
      _accountId != null &&
      _entryCurrencyCode != _currencyOf(_accountId);

  /// The amount to store, computed from the current input; null if no account is chosen, no amount is entered, or there is no rate to convert with.
  EntryAmount? get _resolvedAmount {
    final cents = parseCents(_amount.text);
    if (cents == null || cents <= 0 || _accountId == null) return null;
    return resolveEntryAmount(
      enteredCents: cents,
      entryCurrency: _entryCurrencyCode,
      accountId: _accountId!,
      converter: ref.read(hkdConverterProvider),
      existing: widget.existing,
    );
  }

  /// The two accounts of a transfer have different currencies (the received amount must be entered separately).
  bool get _isCrossCurrency =>
      _isTransfer &&
      _accountId != null &&
      _toAccountId != null &&
      _currencyOf(_accountId) != _currencyOf(_toAccountId);

  /// Estimates the received amount (in cents) from the current rates. Returns null if it cannot be computed (no amount, or no rate).
  int? get _suggestedToAmount {
    final cents = parseCents(_amount.text);
    if (cents == null || cents <= 0 || !_isCrossCurrency) return null;
    return ref
        .read(hkdConverterProvider)
        .convert(cents, _currencyOf(_accountId), _currencyOf(_toAccountId));
  }

  @override
  void dispose() {
    _toAmount.dispose();
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

    // A transfer always uses the account's currency; income and expense may be entered in another currency and are converted before storing
    final entered = parseCents(_amount.text)!;
    final resolved = _isTransfer ? null : _resolvedAmount;

    final companion = TransactionsCompanion(
      date: Value(_date),
      amount: Value(resolved?.amount ?? entered),
      originalAmount: Value(resolved?.originalAmount),
      originalCurrency: Value(resolved?.originalCurrency),
      type: Value(_type),
      accountId: Value(_accountId!),
      toAccountId: Value(_isTransfer ? _toAccountId : null),
      // Cross-currency transfer: use the received amount if entered, otherwise estimate it from the rates; store nothing in other cases
      toAmount: Value(
          _isCrossCurrency ? (parseCents(_toAmount.text) ?? _suggestedToAmount) : null),
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
        title: Text(context.l10n.deleteTransactionTitle),
        content: Text(context.l10n.deleteCannotUndo),
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
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // The currency conversion below reads the converter with ref.read, so watch it here:
    // that keeps it (and the exchange rates) loaded while the form is open, and rebuilds
    // the form if the rates change.
    ref.watch(hkdConverterProvider);

    // When editing an old transaction, show its account even if that account has been archived
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

    // Note suggestions: from notes used before, same-category ones first, filtered by what is typed
    final suggestions = suggestNotes(
      ref.watch(transactionsProvider).value ?? [],
      type: _type,
      categoryId: _categoryId,
      query: _note.text,
    ).where((s) => s != _note.text.trim()).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? context.l10n.editTransaction : context.l10n.newTransaction),
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
                      // show the entry currency's symbol (the account's currency if none was picked)
                      prefixText: currencyInfo(_entryCurrencyCode).symbol,
                      suffixIcon: IconButton(
                        tooltip: context.l10n.calculatorTooltip,
                        icon: const Icon(Icons.calculate_outlined),
                        onPressed: _openCalculator,
                      ),
                    ),
                    // use the built-in calculator instead of the system keyboard
                    readOnly: true,
                    onTap: _openCalculator,
                    validator: (v) {
                      final cents = parseCents(v ?? '');
                      if (cents == null || cents <= 0) {
                        return context.l10n.errorAmountPositive;
                      }
                      if (_isConverting && _resolvedAmount == null) {
                        return context.l10n.errorMissingRate(
                            _entryCurrencyCode, _currencyOf(_accountId));
                      }
                      if (_isConverting && _resolvedAmount!.amount <= 0) {
                        return context.l10n.errorConvertedTooSmall;
                      }
                      return null;
                    },
                  ),
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
                  // Optional: only needed when paying in another currency; the amount is converted to the account's currency at the current rate
                  if (!_isTransfer) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      key: ValueKey('entry-$_accountId'),
                      initialValue: _entryCurrency,
                      decoration: InputDecoration(
                        labelText: context.l10n.fieldEntryCurrency,
                        helperText: _isConverting
                            ? (_resolvedAmount != null
                                ? context.l10n.entryCurrencyConverted(
                                    formatMoney(_resolvedAmount!.amount,
                                        _currencyOf(_accountId)))
                                // Only blame the missing rate once an amount is entered
                                : (parseCents(_amount.text) ?? 0) > 0
                                    ? context.l10n.entryCurrencyNoRate
                                    : context.l10n.entryCurrencyHint)
                            : context.l10n.entryCurrencyHint,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(context.l10n
                              .entryCurrencySameAs(_currencyOf(_accountId))),
                        ),
                        for (final c in supportedCurrencies)
                          DropdownMenuItem<String?>(
                            value: c.code,
                            child: Text('${c.code}　${currencyName(context.l10n, c.code)}'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _entryCurrency = v),
                    ),
                  ],
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
                        return null;
                      },
                    ),
                  if (_isCrossCurrency) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _toAmount,
                      decoration: InputDecoration(
                        labelText: context.l10n
                            .fieldReceivedAmount(_currencyOf(_toAccountId)),
                        prefixText:
                            currencyInfo(_currencyOf(_toAccountId)).symbol,
                        helperText: _suggestedToAmount == null
                            ? context.l10n.receivedAmountNoRate
                            : context.l10n.receivedAmountEstimate(formatMoney(
                                _suggestedToAmount!,
                                _currencyOf(_toAccountId))),
                        suffixIcon: IconButton(
                          tooltip: context.l10n.calculatorTooltip,
                          icon: const Icon(Icons.calculate_outlined),
                          onPressed: () => _openCalculator(_toAmount),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _openCalculator(_toAmount),
                      validator: (v) {
                        final typed = parseCents(v ?? '');
                        if (typed != null && typed <= 0) return context.l10n.errorReceivedPositive;
                        if (typed == null && _suggestedToAmount == null) {
                          return context.l10n.errorReceivedRequired;
                        }
                        return null;
                      },
                    ),
                  ],
                  if (!_isTransfer)
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
                                Text(categoryDisplayName(context.l10n, c)),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) => v == null ? context.l10n.errorSelectCategory : null,
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.fieldDate),
                    subtitle: Text(context.l10n.formatDate(_date)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                  TextFormField(
                    controller: _note,
                    decoration: InputDecoration(labelText: context.l10n.fieldNoteOptional),
                    onChanged: (_) => setState(() {}), // refilter the suggestions
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final s in suggestions)
                          ActionChip(
                            label: Text(s),
                            onPressed: () => setState(() {
                              _note.text = s;
                              _note.selection = TextSelection.collapsed(
                                  offset: s.length);
                            }),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _save, child: Text(context.l10n.save)),
                ],
              ),
            ),
    );
  }
}
