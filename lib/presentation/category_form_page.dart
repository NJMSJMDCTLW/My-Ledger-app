import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';

/// Add or edit a category: a name plus an icon picked from the recommended list.
class CategoryFormPage extends ConsumerStatefulWidget {
  const CategoryFormPage({super.key, this.existing, this.initialType});

  /// Non-null means editing this category; null means adding a new one.
  final Category? existing;

  /// Default type when adding (whichever section the add button was pressed in).
  final CategoryType? initialType;

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  CategoryType _type = CategoryType.expense;
  String _iconKey = 'more';

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      _type = c.type;
      _name.text = c.name;
      _iconKey = categoryIconKey(c);
    } else {
      _type = widget.initialType ?? CategoryType.expense;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final name = v?.trim() ?? '';
    if (name.isEmpty) return context.l10n.nameRequired;
    final categories = ref.read(categoriesProvider).value ?? [];
    final duplicated = categories.any((c) =>
        c.type == _type &&
        c.id != widget.existing?.id &&
        c.name.toLowerCase() == name.toLowerCase());
    return duplicated ? context.l10n.errorDuplicateCategory : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);
    final name = _name.text.trim();

    if (_isEditing) {
      final id = widget.existing!.id;
      // The type cannot change (old transactions already recorded income or expense with this category), so only the name and icon are updated
      await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(name: Value(name), icon: Value(_iconKey)),
      );
    } else {
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: name,
              type: _type,
              icon: Value(_iconKey),
            ),
          );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final db = ref.read(databaseProvider);
    final id = widget.existing!.id;

    // A category already used by transactions or recurring rules cannot be deleted, or those records would end up with no category
    final txCount = (await (db.select(db.transactions)
              ..where((t) => t.categoryId.equals(id)))
            .get())
        .length;
    final ruleCount = (await (db.select(db.recurringRules)
              ..where((r) => r.categoryId.equals(id)))
            .get())
        .length;
    if (!mounted) return;

    if (txCount + ruleCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.cannotDeleteTitle),
          content: Text(context.l10n.categoryInUse(txCount, ruleCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.gotIt),
            ),
          ],
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteCategoryTitle),
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

    await (db.delete(db.categories)..where((c) => c.id.equals(id))).go();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // The duplicate-name check reads the categories with ref.read, so watch them here to keep
    // them loaded while the form is open (otherwise a duplicate could slip through).
    ref.watch(categoriesProvider);

    final theme = Theme.of(context);
    final previewColor = _isEditing
        ? AppTheme.categoryColor(widget.existing!.id)
        : AppTheme.macaron[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? context.l10n.editCategory : context.l10n.newCategory),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: context.l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: previewColor,
                foregroundColor: AppTheme.onMacaron,
                child: Icon(recommendedIcons[_iconKey], size: 36),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<CategoryType>(
              segments: [
                ButtonSegment(value: CategoryType.expense, label: Text(context.l10n.expense)),
                ButtonSegment(value: CategoryType.income, label: Text(context.l10n.income)),
              ],
              selected: {_type},
              // The type cannot be changed when editing
              onSelectionChanged: _isEditing
                  ? null
                  : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: context.l10n.fieldCategoryName),
              maxLength: 30,
              autofocus: !_isEditing,
              validator: _validateName,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.chooseIcon, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in recommendedIcons.entries)
                  _IconChoice(
                    icon: entry.value,
                    selected: entry.key == _iconKey,
                    onTap: () => setState(() => _iconKey = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(context.l10n.save)),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(icon, color: scheme.onSurface),
      ),
    );
  }
}
