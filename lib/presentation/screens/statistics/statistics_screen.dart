import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/transaction_providers.dart';
import '../../widgets/monthly_comparison_card.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _touchedPieIndex = -1;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isLoaded = true);
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _touchedPieIndex = -1;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _touchedPieIndex = -1;
    });
  }

  Color _parseColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = _currentMonth;
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);
    final sixMonthsAgo = DateTime(_currentMonth.year, _currentMonth.month - 5, 1);

    final currentMonthAsync = ref.watch(transactionsByDateRangeProvider(
        (from: firstDay, to: lastDay)));

    final sixMonthsAsync = ref.watch(transactionsByDateRangeProvider(
        (from: sixMonthsAgo, to: lastDay)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMonthSelector(),
            currentMonthAsync.when(
              data: (txs) => _buildCurrentMonthStats(txs),
              loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
            const Divider(height: 48, thickness: 8, color: Color(0xFFF0F0F0)),
            sixMonthsAsync.when(
              data: (txs) => _buildBarChart(txs, sixMonthsAgo),
              loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
            const Divider(height: 48, thickness: 8, color: Color(0xFFF0F0F0)),
            MonthlyComparisonCard(currentMonth: _currentMonth),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMonthStats(List<TransactionEntity> transactions) {
    final expenses = transactions.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('Belum ada pengeluaran di bulan ini.', style: TextStyle(color: Colors.grey))),
      );
    }

    final Map<int, double> categoryTotals = {};
    final Map<int, TransactionEntity> categoryMap = {};

    double totalExpense = 0;
    for (var tx in expenses) {
      categoryTotals[tx.categoryId] = (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
      categoryMap[tx.categoryId] = tx;
      totalExpense += tx.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    int index = 0;
    for (var entry in sortedEntries) {
      final catId = entry.key;
      final amount = entry.value;
      final isTouched = index == _touchedPieIndex;
      final tx = categoryMap[catId]!;
      final color = _parseColor(tx.categoryColor);
      
      final radius = isTouched ? 60.0 : 50.0;
      final value = _isLoaded ? amount : 0.0;

      sections.add(
        PieChartSectionData(
          color: color,
          value: value == 0 ? 0.001 : value,
          title: '', 
          radius: radius,
        ),
      );
      index++;
    }

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedPieIndex = -1;
                      return;
                    }
                    _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: sections,
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 24),
        if (_touchedPieIndex >= 0 && _touchedPieIndex < sortedEntries.length)
          ...[
            Text(
              categoryMap[sortedEntries[_touchedPieIndex].key]!.categoryName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(sortedEntries[_touchedPieIndex].value),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ]
        else
          ...[
             const Text('Total Pengeluaran', style: TextStyle(fontSize: 16, color: Colors.grey)),
             const SizedBox(height: 4),
             Text(
               currencyFormat.format(totalExpense),
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
             ),
          ],
        
        const SizedBox(height: 32),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedEntries.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            final tx = categoryMap[entry.key]!;
            final color = _parseColor(tx.categoryColor);
            final percent = (entry.value / totalExpense) * 100;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Text(tx.categoryIcon),
              ),
              title: Text(tx.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(currencyFormat.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${percent.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBarChart(List<TransactionEntity> transactions, DateTime startMonth) {
    final List<double> incomeData = List.filled(6, 0.0);
    final List<double> expenseData = List.filled(6, 0.0);
    double maxY = 0;

    for (var tx in transactions) {
      int index = (tx.date.year - startMonth.year) * 12 + (tx.date.month - startMonth.month);
      if (index >= 0 && index < 6) {
        if (tx.type == 'income') {
          incomeData[index] += tx.amount;
          if (incomeData[index] > maxY) maxY = incomeData[index];
        } else {
          expenseData[index] += tx.amount;
          if (expenseData[index] > maxY) maxY = expenseData[index];
        }
      }
    }

    if (maxY == 0) maxY = 1000;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 6; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _isLoaded ? incomeData[i] : 0,
              color: AppTheme.accentGreen,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: _isLoaded ? expenseData[i] : 0,
              color: Colors.redAccent,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          barsSpace: 4,
        ),
      );
    }

    final monthFormat = DateFormat('MMM', 'id_ID');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trend 6 Bulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.accentGreen, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Pemasukan', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Pengeluaran', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
                      return BarTooltipItem(
                        currency.format(rod.toY),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          _compactCurrency(value),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index > 5) return const SizedBox.shrink();
                        DateTime date = DateTime(startMonth.year, startMonth.month + index, 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            monthFormat.format(date),
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                barGroups: barGroups,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  String _compactCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}Jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildMonthSelector() {
    final monthFormat = DateFormat('MMMM yyyy', 'id_ID');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
          const SizedBox(width: 16),
          Text(
            monthFormat.format(_currentMonth),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
        ],
      ),
    );
  }
}
