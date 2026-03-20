import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_theme.dart';
import '../providers/transaction_providers.dart';

class MonthlyComparisonCard extends ConsumerWidget {
  final DateTime currentMonth;

  const MonthlyComparisonCard({super.key, required this.currentMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prev = DateTime(currentMonth.year, currentMonth.month - 1, 1);

    final curIncomeAsync = ref.watch(monthlyTotalProvider((type: 'income', month: currentMonth.month, year: currentMonth.year)));
    final curExpenseAsync = ref.watch(monthlyTotalProvider((type: 'expense', month: currentMonth.month, year: currentMonth.year)));
    final prevIncomeAsync = ref.watch(monthlyTotalProvider((type: 'income', month: prev.month, year: prev.year)));
    final prevExpenseAsync = ref.watch(monthlyTotalProvider((type: 'expense', month: prev.month, year: prev.year)));

    final monthFormat = DateFormat('MMM yyyy', 'id_ID');

    // Collect all 4 providers — only render content when all are loaded
    return curIncomeAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (curIncome) => curExpenseAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (curExpense) => prevIncomeAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (prevIncome) => prevExpenseAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (prevExpense) {
              final curNet = curIncome - curExpense;
              final prevNet = prevIncome - prevExpense;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bulan Ini vs Bulan Lalu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                const Expanded(flex: 2, child: SizedBox()),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    monthFormat.format(prev),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    monthFormat.format(currentMonth),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 13),
                                  ),
                                ),
                                const Expanded(flex: 2, child: SizedBox()),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          _ComparisonRow(label: 'Pemasukan', current: curIncome, previous: prevIncome, isPositiveGood: true),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _ComparisonRow(label: 'Pengeluaran', current: curExpense, previous: prevExpense, isPositiveGood: false),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _ComparisonRow(label: 'Saldo Bersih', current: curNet, previous: prevNet, isPositiveGood: true, isBold: true),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double current;
  final double previous;
  final bool isPositiveGood;
  final bool isBold;

  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.isPositiveGood,
    this.isBold = false,
  });

  String _delta() {
    if (previous == 0) return current > 0 ? '+∞%' : '0%';
    final pct = ((current - previous) / previous.abs() * 100);
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
  }

  bool get _isUp => current >= previous;

  Color get _arrowColor {
    final improved = isPositiveGood ? _isUp : !_isUp;
    return improved ? AppTheme.accentGreen : Colors.red;
  }

  IconData get _arrowIcon => _isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final fontWeight = isBold ? FontWeight.bold : FontWeight.normal;
    final fontSize = isBold ? 14.0 : 13.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Label
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: Colors.grey[700])),
          ),
          // Previous month value
          Expanded(
            flex: 3,
            child: Text(
              currency.format(previous),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
            ),
          ),
          // Current month value
          Expanded(
            flex: 3,
            child: Text(
              currency.format(current),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: isBold ? AppTheme.primaryGreen : Colors.black87),
            ),
          ),
          // Delta indicator
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_arrowIcon, color: _arrowColor, size: 14),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    _delta(),
                    style: TextStyle(fontSize: 11, color: _arrowColor, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
