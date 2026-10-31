import 'package:flutter/material.dart';
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

  static const _titles = ['我的記帳本', '統計', '帳戶', '信用卡', '固定收支', '分類管理', '匯率'];

  int _index = _home;

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  /// The button at the bottom right of each tab: record a transaction on Home; add an account, credit card, recurring rule or category on the other tabs; Statistics has none.
  Widget? get _fab => switch (_index) {
        _home => FloatingActionButton.extended(
            onPressed: () => _open(const TransactionFormPage()),
            icon: const Icon(Icons.add),
            label: const Text('記一筆'),
          ),
        _accounts => FloatingActionButton.extended(
            onPressed: () => _open(const AccountFormPage()),
            icon: const Icon(Icons.add),
            label: const Text('新增帳戶'),
          ),
        _creditCards => FloatingActionButton.extended(
            onPressed: () => _open(
                const AccountFormPage(initialType: AccountType.creditCard)),
            icon: const Icon(Icons.add),
            label: const Text('新增信用卡'),
          ),
        _recurring => FloatingActionButton.extended(
            onPressed: () => _open(const RecurringFormPage()),
            icon: const Icon(Icons.add),
            label: const Text('新增固定收支'),
          ),
        _categories => FloatingActionButton.extended(
            onPressed: () => _open(const CategoryFormPage()),
            icon: const Icon(Icons.add),
            label: const Text('新增分類'),
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: NavigationDrawer(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          Navigator.pop(context); // close the drawer automatically after choosing
        },
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(28, 24, 16, 16),
            child: Text(
              '我的記帳本',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('首頁'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: Text('統計'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: Text('帳戶'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: Text('信用卡'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.event_repeat_outlined),
            selectedIcon: Icon(Icons.event_repeat),
            label: Text('固定收支'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: Text('分類管理'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: Text('匯率'),
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
        ],
      ),
    );
  }
}
