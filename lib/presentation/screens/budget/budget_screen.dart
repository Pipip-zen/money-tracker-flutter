import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/budget_providers.dart';
import '../../providers/category_providers.dart';
import '../../../core/utils/icon_utils.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  void _previousMonth() => setState(() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
  });

  void _nextMonth() => setState(() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
  });

  Color _progressColor(double percent) {
    if (percent < 0.6) return AppTheme.accentGreen;
    if (percent < 0.8) return Colors.orange;
    return Colors.red;
  }

  Color _parseColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _openBudgetSheet(
    BuildContext context,
    CategoryEntity category,
    BudgetEntity? existingBudget,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BudgetEditSheet(
        category: category,
        month: _currentMonth.month,
        year: _currentMonth.year,
        existingBudget: existingBudget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy', 'id_ID');
    final budgetsAsync = ref.watch(
      budgetsProvider(BudgetFilter(month: _currentMonth.month, year: _currentMonth.year)),
    );
    final categoriesAsync = ref.watch(categoriesByTypeProvider('expense'));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Anggaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                const SizedBox(width: 16),
                Text(
                  monthFormat.format(_currentMonth),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Text('Belum ada kategori pengeluaran.'),
                  );
                }
                return budgetsAsync.when(
                  data: (budgets) {
                    final currencyFormat = NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp',
                      decimalDigits: 0,
                    );
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final budget = budgets
                            .where((b) => b.categoryId == cat.id)
                            .firstOrNull;
                        final spent = budget?.spentAmount ?? 0.0;
                        final limit = budget?.limitAmount ?? 0.0;
                        final percent = (limit > 0)
                            ? (spent / limit).clamp(0.0, 1.0)
                            : 0.0;
                        final catColor = _parseColor(cat.color);

                        return GestureDetector(
                          onTap: () => _openBudgetSheet(context, cat, budget),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: catColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          child: Icon(
                                            IconUtils.getIcon(cat.icon),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          cat.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    budget == null
                                        ? OutlinedButton(
                                            onPressed: () => _openBudgetSheet(
                                              context,
                                              cat,
                                              null,
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppTheme.primaryGreen,
                                              side: const BorderSide(
                                                color: AppTheme.primaryGreen,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              minimumSize: Size.zero,
                                            ),
                                            child: const Text(
                                              'Set Anggaran',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          )
                                        : Text(
                                            currencyFormat.format(limit),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                  ],
                                ),
                                if (budget != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 8,
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _progressColor(percent),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Terpakai: ${currencyFormat.format(spent)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        limit > spent
                                            ? 'Sisa: ${currencyFormat.format(limit - spent)}'
                                            : 'Melebihi ${currencyFormat.format(spent - limit)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: limit > spent
                                              ? AppTheme.accentGreen
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetEditSheet extends ConsumerStatefulWidget {
  final CategoryEntity category;
  final int month;
  final int year;
  final BudgetEntity? existingBudget;

  const _BudgetEditSheet({
    required this.category,
    required this.month,
    required this.year,
    this.existingBudget,
  });

  @override
  ConsumerState<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<_BudgetEditSheet> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    _amountController = TextEditingController(
      text: widget.existingBudget != null
          ? formatter.format(widget.existingBudget!.limitAmount).trim()
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah anggaran harus lebih dari 0')),
      );
      return;
    }

    final budget = BudgetEntity(
      id: widget.existingBudget?.id ?? 0,
      categoryId: widget.category.id,
      limitAmount: amount,
      month: widget.month,
      year: widget.year,
    );

    try {
      await ref.read(upsertBudgetProvider.notifier).upsertBudget(budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anggaran berhasil disimpan!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete() async {
    final id = widget.existingBudget!.id;
    try {
      await ref.read(upsertBudgetProvider.notifier).deleteBudget(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Anggaran dihapus')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                  child: Icon(
                    IconUtils.getIcon(widget.category.icon),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Anggaran: ${widget.category.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Batas Anggaran',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (widget.existingBudget != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hapus Anggaran',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final intValue = int.tryParse(
      newValue.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (intValue == null) return oldValue;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    final newString = formatter.format(intValue).trim();
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
