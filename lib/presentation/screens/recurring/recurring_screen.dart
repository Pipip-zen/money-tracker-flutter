import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../data/database/app_database.dart';
import '../../../presentation/providers/category_providers.dart';
import '../../../presentation/providers/database_provider.dart';

// --------------- PROVIDERS ---------------

final _recurringStreamProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.recurringTransactionDao.watchAllRecurring();
});

// --------------- SCREEN ---------------

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(_recurringStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Rutin', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddSheet(context, null),
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }
          return categoriesAsync.when(
            data: (categories) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _RecurringTile(item: items[index], categories: categories);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () => _openAddSheet(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddSheet(BuildContext context, RecurringTransaction? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddRecurringSheet(existing: existing),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.repeat, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Belum ada transaksi rutin', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tambah transaksi yang berulang\nseperti gaji atau tagihan bulanan.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// --------------- TILE ---------------

class _RecurringTile extends ConsumerWidget {
  final RecurringTransaction item;
  final List<CategoryEntity> categories;

  const _RecurringTile({required this.item, required this.categories});

  Color _parseColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  String _frequencyLabel(String freq) {
    switch (freq) {
      case 'daily': return 'Harian';
      case 'weekly': return 'Mingguan';
      default: return 'Bulanan';
    }
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddRecurringSheet(existing: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final category = categories.where((c) => c.id == item.categoryId).firstOrNull;
    final catColor = category != null ? _parseColor(category.color) : Colors.grey;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Transaksi Rutin'),
            content: const Text('Apakah Anda yakin ingin menghapus transaksi rutin ini?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await (db.delete(db.recurringTransactions)..where((t) => t.id.equals(item.id))).go();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi rutin dihapus')),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
          border: Border.all(color: item.isActive ? Colors.transparent : Colors.grey[200]!),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: catColor.withValues(alpha: item.isActive ? 0.2 : 0.07),
            child: category != null ? Icon(IconData(category.icon, fontFamily: 'MaterialIcons'), size: 20, color: item.isActive ? null : Colors.grey) : Icon(Icons.monetization_on, size: 20, color: item.isActive ? null : Colors.grey),
          ),
          title: Row(
            children: [
              Text(category?.name ?? 'Kategori', style: TextStyle(fontWeight: FontWeight.bold, color: item.isActive ? null : Colors.grey)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_frequencyLabel(item.frequency), style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${item.type == 'income' ? '+' : '-'}${currencyFormat.format(item.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: item.type == 'income' ? AppTheme.accentGreen : Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Text('Jatuh tempo: ${dateFormat.format(item.nextDueDate)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          trailing: Switch(
            value: item.isActive,
            activeThumbColor: AppTheme.accentGreen,
            onChanged: (val) async {
              await db.recurringTransactionDao.toggleActive(item.id, val);
            },
          ),
          onTap: () => _openEdit(context),
        ),
      ),
    );
  }
}

// --------------- ADD/EDIT SHEET ---------------

class AddRecurringSheet extends ConsumerStatefulWidget {
  final RecurringTransaction? existing;
  const AddRecurringSheet({super.key, this.existing});

  @override
  ConsumerState<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<AddRecurringSheet> {
  late String _selectedType;
  late String _selectedFrequency;
  late DateTime _startDate;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  CategoryEntity? _selectedCategory;

  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];

  String _freqLabel(String f) {
    switch (f) {
      case 'daily': return 'Harian';
      case 'weekly': return 'Mingguan';
      default: return 'Bulanan';
    }
  }

  Color _parseColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _selectedType = e.type;
      _selectedFrequency = e.frequency;
      _startDate = e.nextDueDate;
      _amountController.text = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(e.amount).trim();
      _noteController.text = e.note ?? '';
    } else {
      _selectedType = 'expense';
      _selectedFrequency = 'monthly';
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah harus lebih dari 0')));
      return;
    }
    if (_selectedCategory == null && widget.existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu')));
      return;
    }

    final db = ref.read(databaseProvider);
    final companion = RecurringTransactionsCompanion(
      id: widget.existing != null ? Value(widget.existing!.id) : const Value.absent(),
      amount: Value(amount),
      note: Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
      type: Value(_selectedType),
      categoryId: Value(_selectedCategory?.id ?? widget.existing!.categoryId),
      frequency: Value(_selectedFrequency),
      nextDueDate: Value(_startDate),
      isActive: const Value(true),
    );

    try {
      if (widget.existing == null) {
        await db.recurringTransactionDao.insertRecurring(companion);
      } else {
        await db.recurringTransactionDao.updateRecurring(companion);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil disimpan!'), backgroundColor: AppTheme.accentGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_selectedType));
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(height: 4, width: 40,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing == null ? 'Tambah Transaksi Rutin' : 'Ubah Transaksi Rutin',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                  ButtonSegment(value: 'income', label: Text('Pemasukan')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (s) {
                  setState(() { _selectedType = s.first; _selectedCategory = null; });
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CurrencyFormatter()],
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              const Text('Frekuensi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: _frequencies.map((f) {
                  final isSelected = _selectedFrequency == f;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Center(child: Text(_freqLabel(f))),
                        selected: isSelected,
                        selectedColor: AppTheme.accentGreen.withValues(alpha: 0.2),
                        onSelected: (_) => setState(() => _selectedFrequency = f),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (cats) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cats.map((cat) {
                      final isSelected = _selectedCategory?.id == cat.id ||
                          (widget.existing != null && widget.existing?.categoryId == cat.id && _selectedCategory == null);
                      final color = _parseColor(cat.color);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(IconData(cat.icon, fontFamily: 'MaterialIcons'), size: 18), const SizedBox(width: 6), Text(cat.name)]),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          selectedColor: color.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => const Text('Error'),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tanggal Mulai', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(dateFormat.format(_startDate)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final intValue = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intValue == null) return oldValue;
    final newString = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(intValue).trim();
    return TextEditingValue(text: newString, selection: TextSelection.collapsed(offset: newString.length));
  }
}
