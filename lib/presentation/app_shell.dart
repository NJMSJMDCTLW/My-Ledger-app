import 'package:flutter/material.dart';
import 'package:hello_ledger/core/l10n_context.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/presentation/account_form_page.dart';
import 'package:hello_ledger/presentation/category_form_page.dart';
import 'package:hello_ledger/presentation/tabs/accounts_tab.dart';
import 'package:hello_ledger/presentation/tabs/categories_tab.dart';
import 'package:hello_ledger/presentation/tabs/credit_cards_tab.dart';
import 'package:hello_ledger/presentation/recurring_form_page.dart';
import 'package:hello_ledger/presentation/tabs/home_tab.dart';
import 'package:hello_ledger/presentation/tabs/rates_tab.dart';
import 'package:hello_ledger/presentation/tabs/recurring_tab.dart';
import 'package:hello_ledger/presentation/tabs/settings_tab.dart';
import 'package:hello_ledger/presentation/tabs/stats_tab.dart';
import 'package:hello_ledger/presentation/transaction_form_page.dart';

/// The outer frame: the hamburger button at the top left opens the drawer, which switches between tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _home = 0;
  static const _stats = 1;
  static const _accounts = 2;
  static const _creditCards = 3;
  static const _recurring = 4;
  static const _categories = 5;
  static const _rates = 6;
  static const _settings = 7;

  int _index = _home;

  String _title(BuildContext context) {
    final l10n = context.l10n;
    return switch (_index) {
      _home => l10n.appTitle,
      _stats => l10n.navStatistics,
      _accounts => l10n.navAccounts,
      _creditCards => l10n.navCreditCards,
      _recurring => l10n.navRecurring,
      _categories => l10n.navCategories,
      _rates => l10n.navRates,
      _settings => l10n.settings,
      _ => l10n.appTitle,
    };
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  /// The button at the bottom right of each tab: record a transaction on Home; add an account, credit card, recurring rule or category on the other tabs; Statistics has none.
  Widget? get _fab => switch (_index) {
        _home => FloatingActionButton.extended(
            onPressed: () => _open(const TransactionFormPage()),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.fabAddTransaction),
          ),
        _accounts => FloatingActionButton.extended(
            onPressed: () => _open(const AccountFormPage()),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.fabAddAccount),
          ),
        _creditCards => FloatingActionButton.extended(
            onPressed: () => _open(
                const AccountFormPage(initialType: AccountType.creditCard)),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.fabAddCreditCard),
          ),
        _recurring => FloatingActionButton.extended(
            onPressed: () => _open(const RecurringFormPage()),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.fabAddRecurring),
          ),
        _categories => FloatingActionButton.extended(
            onPressed: () => _open(const CategoryFormPage()),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.fabAddCategory),
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title(context))),
      drawer: NavigationDrawer(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          Navigator.pop(context); // close the drawer automatically after choosing
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
            child: Text(
              context.l10n.appTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: Text(context.l10n.navHome),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: Text(context.l10n.navStatistics),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: Text(context.l10n.navAccounts),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.credit_card_outlined),
            selectedIcon: const Icon(Icons.credit_card),
            label: Text(context.l10n.navCreditCards),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.event_repeat_outlined),
            selectedIcon: const Icon(Icons.event_repeat),
            label: Text(context.l10n.navRecurring),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category),
            label: Text(context.l10n.navCategories),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.currency_exchange_outlined),
            selectedIcon: const Icon(Icons.currency_exchange),
            label: Text(context.l10n.navRates),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Text(context.l10n.settings),
          ),
        ],
      ),
      floatingActionButton: _fab,
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(onOpenStats: () => setState(() => _index = _stats)),
          const StatsTab(),
          const AccountsTab(),
          const CreditCardsTab(),
          const RecurringTab(),
          const CategoriesTab(),
          const RatesTab(),
          const SettingsTab(),
        ],
      ),
    );
  }
}
