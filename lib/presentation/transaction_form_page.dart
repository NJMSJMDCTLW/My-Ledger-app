import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/currencies.dart';
import 'package:hello_ledger/core/entry_amount.dart';
import 'package:hello_ledger/core/money.dart';
import 'package:hello_ledger/core/note_suggestions.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/widgets/calculator_sheet.dart';
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
  final _toAmount = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;

  /// 使用者選的輸入貨幣；null 代表和帳戶貨幣相同（選填，預設就是 null）。
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
      // 當初用別的貨幣輸入的，編輯時顯示原始金額與貨幣
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
      // 新增交易：一進來就打開計算機，可以直接輸入金額
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final accounts = ref.read(accountsProvider).value ?? [];
        if (mounted && accounts.isNotEmpty) _openCalculator();
      });
    }
  }

  /// 打開計算機，把結果填進 [target]（預設是金額欄）。
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

  /// 金額實際是用哪個貨幣輸入的：有選就用選的，沒選就是帳戶的貨幣。轉帳一律用帳戶的貨幣。
  String get _entryCurrencyCode => _isTransfer
      ? _currencyOf(_accountId)
      : (_entryCurrency ?? _currencyOf(_accountId));

  /// 輸入貨幣和帳戶貨幣不同，需要換算。
  bool get _isConverting =>
      !_isTransfer &&
      _accountId != null &&
      _entryCurrencyCode != _currencyOf(_accountId);

  /// 依目前輸入算出要存的金額；帳戶還沒選、金額沒填、或沒有匯率可換算時回傳 null。
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

  /// 轉帳的兩個帳戶貨幣不同（要另外填轉入金額）。
  bool get _isCrossCurrency =>
      _isTransfer &&
      _accountId != null &&
      _toAccountId != null &&
      _currencyOf(_accountId) != _currencyOf(_toAccountId);

  /// 依目前匯率估算轉入金額（單位：分）。算不出來（沒填金額、沒匯率）回傳 null。
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

    // 轉帳固定用帳戶貨幣；收入、支出可能用別的貨幣輸入，換算後才存
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
      // 跨貨幣轉帳：用填的轉入金額，沒填就用匯率估算；其他情況不存
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

    // 備註推薦：來自過去用過的備註，同類別的排前面，打字時會依內容篩選
    final suggestions = suggestNotes(
      ref.watch(transactionsProvider).value ?? [],
      type: _type,
      categoryId: _categoryId,
      query: _note.text,
    ).where((s) => s != _note.text.trim()).toList();

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
                    decoration: InputDecoration(
                      labelText: '金額',
                      // 顯示輸入貨幣的符號（沒特別選就是帳戶的貨幣）
                      prefixText: currencyInfo(_entryCurrencyCode).symbol,
                      suffixIcon: IconButton(
                        tooltip: '計算機',
                        icon: const Icon(Icons.calculate_outlined),
                        onPressed: _openCalculator,
                      ),
                    ),
                    // 用內建計算機輸入，不跳出系統鍵盤
                    readOnly: true,
                    onTap: _openCalculator,
                    validator: (v) {
                      final cents = parseCents(v ?? '');
                      if (cents == null || cents <= 0) return '請輸入大於 0 的金額';
                      if (_isConverting && _resolvedAmount == null) {
                        return '$_entryCurrencyCode 或 ${_currencyOf(_accountId)} '
                            '還沒設定匯率，請先到「匯率」設定';
                      }
                      if (_isConverting && _resolvedAmount!.amount <= 0) {
                        return '換算後金額太小';
                      }
                      return null;
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
                  // 選填：用別的貨幣付款時才需要選，系統會依匯率換成帳戶的貨幣
                  if (!_isTransfer) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      key: ValueKey('entry-$_accountId'),
                      initialValue: _entryCurrency,
                      decoration: InputDecoration(
                        labelText: '輸入貨幣（選填）',
                        helperText: _isConverting
                            ? (_resolvedAmount == null
                                ? '尚未設定匯率，無法換算'
                                : '折合 ${formatMoney(_resolvedAmount!.amount, _currencyOf(_accountId))}'
                                    '，記在帳戶裡')
                            : '用別的貨幣付款時才需要選，會依匯率換成帳戶的貨幣',
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('與帳戶相同（${_currencyOf(_accountId)}）'),
                        ),
                        for (final c in supportedCurrencies)
                          DropdownMenuItem<String?>(
                            value: c.code,
                            child: Text('${c.code}　${c.name}'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _entryCurrency = v),
                    ),
                  ],
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
                    ),
                  if (_isCrossCurrency) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _toAmount,
                      decoration: InputDecoration(
                        labelText: '轉入金額（${_currencyOf(_toAccountId)}）',
                        prefixText:
                            currencyInfo(_currencyOf(_toAccountId)).symbol,
                        helperText: _suggestedToAmount == null
                            ? '兩種貨幣的匯率還沒設定好，請自己填實際收到的金額'
                            : '依目前匯率約 '
                                '${formatMoney(_suggestedToAmount!, _currencyOf(_toAccountId))}'
                                '，留空就用這個金額',
                        suffixIcon: IconButton(
                          tooltip: '計算機',
                          icon: const Icon(Icons.calculate_outlined),
                          onPressed: () => _openCalculator(_toAmount),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _openCalculator(_toAmount),
                      validator: (v) {
                        final typed = parseCents(v ?? '');
                        if (typed != null && typed <= 0) return '轉入金額要大於 0';
                        if (typed == null && _suggestedToAmount == null) {
                          return '請填轉入金額';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (!_isTransfer)
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
                    onChanged: (_) => setState(() {}), // 重新篩選推薦清單
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
                  FilledButton(onPressed: _save, child: const Text('儲存')),
                ],
              ),
            ),
    );
  }
}
