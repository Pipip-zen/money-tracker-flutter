import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../providers/category_providers.dart';
import '../providers/transaction_providers.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  final TransactionEntity? existingTransaction;

  const AddTransactionBottomSheet({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends ConsumerState<AddTransactionBottomSheet> {
  late String _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  CategoryEntity? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _selectedType = tx.type;
      
      final intValue = tx.amount.toInt();
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
      _amountController.text = formatter.format(intValue).trim();

      _selectedCategory = CategoryEntity(
        id: tx.categoryId,
        name: tx.categoryName,
        icon: tx.categoryIcon,
        color: tx.categoryColor,
        type: tx.type,
      );
      _noteController.text = tx.note ?? '';
      _selectedDate = tx.date;
    } else {
      _selectedType = 'expense';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    final entity = TransactionEntity(
      id: widget.existingTransaction?.id ?? 0,
      amount: amount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: _selectedDate,
      type: _selectedType,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      categoryIcon: _selectedCategory!.icon,
      categoryColor: _selectedCategory!.color,
    );

    final notifier = ref.read(addTransactionProvider.notifier);
    
    try {
      if (widget.existingTransaction == null) {
        await notifier.addTransaction(entity);
      } else {
        await notifier.updateTransaction(entity);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil disimpan!'), 
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Text(
                      widget.existingTransaction == null ? 'Tambah Transaksi' : 'Ubah Transaksi',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                        ButtonSegment(value: 'income', label: Text('Pemasukan')),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                          _selectedCategory = null;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return _selectedType == 'income' 
                                ? AppTheme.accentGreen.withValues(alpha: 0.2) 
                                : Colors.red.withValues(alpha: 0.2);
                          }
                          return Colors.transparent;
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildCategorySelector(),
                    const SizedBox(height: 24),

                    const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildTableCalendar(),
                    const SizedBox(height: 24),

                    const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Opsional',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Simpan Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_selectedType));

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Text('Belum ada kategori.');
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory?.id == cat.id;
              
              String hex = cat.color.replaceAll('#', '');
              if (hex.length == 6) hex = 'FF$hex';
              final catColor = Color(int.parse(hex, radix: 16));

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.icon),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? cat : null;
                    });
                  },
                  selectedColor: catColor.withValues(alpha: 0.2),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isSelected ? catColor : Colors.grey[300]!),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Text('Gagal memuat kategori'),
    );
  }

  Widget _buildTableCalendar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _selectedDate,
        currentDay: _selectedDate,
        calendarFormat: CalendarFormat.week,
        availableCalendarFormats: const {CalendarFormat.week: 'Week'},
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
          });
        },
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final intValue = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intValue == null) return oldValue;

    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final newString = formatter.format(intValue).trim();

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
