import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'statistics/statistics_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/add_transaction_sheet.dart';

final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {

  final List<Widget> _pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    ref.read(selectedTabIndexProvider.notifier).state = index;
  }

  void _openAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return const AddTransactionBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => _openAddTransaction(context),
        elevation: 4.0,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.zero,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.transparent,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Statistik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
