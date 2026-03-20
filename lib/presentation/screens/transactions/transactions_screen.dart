import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/export_service.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/category_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../widgets/add_transaction_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  CategoryEntity? _selectedCategory;
  List<TransactionEntity> _lastLoaded = [];

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: 40, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Text('Ekspor Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.table_chart, color: AppTheme.primaryGreen)),
              title: const Text('Ekspor ke CSV'),
              subtitle: const Text('File spreadsheet (.csv)'),
              onTap: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ExportService.exportToCSV(_lastLoaded);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Gagal ekspor: $e')));
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.picture_as_pdf, color: Colors.red)),
              title: const Text('Ekspor ke PDF'),
              subtitle: const Text('Laporan bulanan (.pdf)'),
              onTap: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ExportService.exportToPDF(_lastLoaded, _currentMonth.month, _currentMonth.year);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Gagal ekspor: $e')));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  Map<DateTime, List<TransactionEntity>> _groupTransactions(List<TransactionEntity> transactions) {
    final Map<DateTime, List<TransactionEntity>> grouped = {};
    for (var tx in transactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(tx);
    }
    return Map.fromEntries(
        grouped.entries.toList()..sort((e1, e2) => e2.key.compareTo(e1.key)));
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Hari Ini';
    if (date == yesterday) return 'Kemarin';

    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  void _deleteTransaction(int id) async {
    try {
      await ref.read(addTransactionProvider.notifier).deleteTransaction(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus')));
      }
    }
  }

  void _openEditSheet(TransactionEntity tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddTransactionBottomSheet(existingTransaction: tx);
      },
    );
  }

  Color _parseColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);
    
    final transactionsAsync = ref.watch(transactionsByDateRangeProvider(
      (from: _currentMonth, to: lastDay)
    ));

    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Ekspor',
            onPressed: () => _showExportSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(categoriesAsync),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                var filtered = transactions;
                _lastLoaded = transactions; // cache for export
                if (_selectedCategory != null) {
                  filtered = filtered.where((t) => t.categoryId == _selectedCategory!.id).toList();
                }

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                final grouped = _groupTransactions(filtered);
                final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final date = grouped.keys.elementAt(index);
                    final txList = grouped[date]!;
                    
                    double dailyIncome = 0;
                    double dailyExpense = 0;
                    for (var tx in txList) {
                      if (tx.type == 'income') {
                        dailyIncome += tx.amount;
                      } else {
                        dailyExpense += tx.amount;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey[100],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDateHeader(date),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              Row(
                                children: [
                                  if (dailyIncome > 0)
                                    Text('+${currencyFormat.format(dailyIncome)}', style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12)),
                                  if (dailyIncome > 0 && dailyExpense > 0)
                                    const SizedBox(width: 8),
                                  if (dailyExpense > 0)
                                    Text('-${currencyFormat.format(dailyExpense)}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ...txList.map((tx) {
                          final isIncome = tx.type == 'income';
                          final color = _parseColor(tx.categoryColor);

                          return Dismissible(
                            key: ValueKey(tx.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Transaksi'),
                                  content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              _deleteTransaction(tx.id);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              color: Colors.red,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.2),
                                child: Text(tx.categoryIcon, style: const TextStyle(fontSize: 20)),
                              ),
                              title: Text(tx.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: tx.note != null && tx.note!.isNotEmpty 
                                  ? Text(tx.note!, maxLines: 1, overflow: TextOverflow.ellipsis) 
                                  : null,
                              trailing: Text(
                                '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                style: TextStyle(
                                  color: isIncome ? AppTheme.accentGreen : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _openEditSheet(tx),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Gagal memuat: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AsyncValue<List<CategoryEntity>> categoriesAsync) {
    final monthFormat = DateFormat('MMMM yyyy', 'id_ID');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
              Text(
                monthFormat.format(_currentMonth),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
            ],
          ),
          
          categoriesAsync.when(
            data: (categories) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<CategoryEntity?>(
                  value: _selectedCategory,
                  hint: const Text('Semua Kategori'),
                  icon: const Icon(Icons.filter_list),
                  items: [
                    const DropdownMenuItem<CategoryEntity?>(
                      value: null,
                      child: Text('Semua'),
                    ),
                    ...categories.map((cat) {
                      return DropdownMenuItem<CategoryEntity?>(
                        value: cat,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.icon),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60, // Limit width to prevent overflow
                              child: Text(cat.name, overflow: TextOverflow.ellipsis),
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (cat) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                ),
              );
            },
            loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, st) => const Icon(Icons.error, color: Colors.red),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Belum ada transaksi di bulan ini', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}
