import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_ledger/core/app_theme.dart';
import 'package:hello_ledger/core/category_icons.dart';
import 'package:hello_ledger/core/category_names.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/data/providers.dart';
import 'package:hello_ledger/presentation/category_form_page.dart';

/// The category management tab: expense and income categories, which can be added, renamed, given a new icon, or deleted.
class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? [];

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _Section(
          title: context.l10n.categoriesExpenseSection,
          categories:
              categories.where((c) => c.type == CategoryType.expense).toList(),
        ),
        _Section(
          title: context.l10n.categoriesIncomeSection,
          categories:
              categories.where((c) => c.type == CategoryType.income).toList(),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.categories});

  final String title;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 4),
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        for (final c in categories)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CategoryFormPage(existing: c),
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: AppTheme.categoryColor(c.id),
                foregroundColor: AppTheme.onMacaron,
                child: Icon(categoryIcon(c), size: 20),
              ),
              title: Text(categoryDisplayName(context.l10n, c)),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}
