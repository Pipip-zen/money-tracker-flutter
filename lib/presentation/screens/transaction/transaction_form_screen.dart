import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/wallet.dart';
import '../../providers/category_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/wallet/wallet_picker_sheet.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionEntity? transaction;
  final int? initialWalletId;

  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.initialWalletId,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _selectedType;
  CategoryEntity? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _didSetInitialWallet = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _selectedType = tx?.type ?? 'expense';
    if (tx != null) {
      _amountController.text = NumberFormat.decimalPattern(
        'id_ID',
      ).format(tx.amount);
      _noteController.text = tx.note ?? '';
      _selectedDate = tx.date;
      if (tx.categoryId != null) {
        _selectedCategory = CategoryEntity(
          id: tx.categoryId!,
          name: tx.categoryName,
          icon: tx.categoryIcon,
          color: tx.categoryColor,
          type: tx.type,
        );
      }
    }

    Future.microtask(() {
      ref.read(selectedWalletIdProvider.notifier).state =
          tx?.walletId ?? widget.initialWalletId;
      ref.read(selectedToWalletIdProvider.notifier).state = tx?.toWalletId;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickWallet({required bool isToWallet}) async {
    final provider = isToWallet
        ? selectedToWalletIdProvider
        : selectedWalletIdProvider;
    final selected = await WalletPickerSheet.show(
      context,
      selectedWalletId: ref.read(provider),
    );
    if (selected == null) return;
    ref.read(provider.notifier).state = selected;
  }

  Future<void> _submit() async {
    final amount = _parseMoney(_amountController.text);
    final walletId = ref.read(selectedWalletIdProvider);
    final toWalletId = ref.read(selectedToWalletIdProvider);

    if (amount <= 0) {
      _showMessage('Nominal tidak boleh 0');
      return;
    }
    if (walletId == null) {
      _showMessage('Pilih dompet terlebih dahulu');
      return;
    }
    if (_selectedType == 'transfer') {
      if (toWalletId == null) {
        _showMessage('Pilih dompet tujuan');
        return;
      }
      if (walletId == toWalletId) {
        _showMessage('Dompet asal dan tujuan tidak boleh sama');
        return;
      }
    } else if (_selectedCategory == null) {
      _showMessage('Pilih kategori terlebih dahulu');
      return;
    }

    final tx = TransactionEntity(
      id: widget.transaction?.id ?? 0,
      amount: amount,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      date: _selectedDate,
      type: _selectedType,
      categoryId: _selectedType == 'transfer' ? null : _selectedCategory!.id,
      walletId: walletId,
      toWalletId: _selectedType == 'transfer' ? toWalletId : null,
      categoryName: _selectedType == 'transfer'
          ? 'Transfer'
          : _selectedCategory!.name,
      categoryIcon: _selectedType == 'transfer'
          ? Icons.swap_horiz_rounded.codePoint
          : _selectedCategory!.icon,
      categoryColor: _selectedType == 'transfer'
          ? '#2196F3'
          : _selectedCategory!.color,
    );

    final notifier = ref.read(addTransactionProvider.notifier);
    if (widget.transaction == null) {
      await notifier.addTransaction(tx);
    } else {
      await notifier.updateTransaction(tx);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final defaultWallet = ref.watch(defaultWalletProvider);
    final selectedWalletId = ref.watch(selectedWalletIdProvider);
    final selectedToWalletId = ref.watch(selectedToWalletIdProvider);
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const [];

    defaultWallet.whenData((wallet) {
      if (_didSetInitialWallet || selectedWalletId != null || wallet == null) {
        return;
      }
      _didSetInitialWallet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedWalletIdProvider.notifier).state = wallet.id;
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Keluar')),
                ButtonSegment(value: 'income', label: Text('Masuk')),
                ButtonSegment(value: 'transfer', label: Text('Transfer')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (value) {
                setState(() {
                  _selectedType = value.first;
                  _selectedCategory = null;
                });
                if (_selectedType != 'transfer') {
                  ref.read(selectedToWalletIdProvider.notifier).state = null;
                }
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _WalletField(
              label: _selectedType == 'transfer' ? 'Dari Dompet' : 'Dompet',
              walletId: selectedWalletId,
              wallets: wallets,
              onTap: () => _pickWallet(isToWallet: false),
            ),
            if (_selectedType == 'transfer') ...[
              const SizedBox(height: 12),
              _WalletField(
                label: 'Ke Dompet',
                walletId: selectedToWalletId,
                wallets: wallets,
                onTap: () => _pickWallet(isToWallet: true),
              ),
            ],
            if (_selectedType != 'transfer') ...[
              const SizedBox(height: 20),
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _buildCategorySelector(),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal'),
              subtitle: Text(
                DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
              ),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Transaksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_selectedType));

    return categoriesAsync.when(
      data: (categories) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((cat) {
          final selected = _selectedCategory?.id == cat.id;
          return ChoiceChip(
            selected: selected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(IconUtils.getIcon(cat.icon), size: 18),
                const SizedBox(width: 6),
                Text(cat.name),
              ],
            ),
            onSelected: (_) => setState(() => _selectedCategory = cat),
          );
        }).toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Gagal memuat kategori'),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WalletField extends StatelessWidget {
  final String label;
  final int? walletId;
  final List<Wallet> wallets;
  final VoidCallback onTap;

  const _WalletField({
    required this.label,
    required this.walletId,
    required this.wallets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wallet = wallets.where((item) => item.id == walletId).firstOrNull;
    final color = wallet == null ? null : _parseColor(wallet.colorHex);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color?.withValues(alpha: 0.14),
              child: Icon(
                wallet == null
                    ? Icons.wallet_rounded
                    : _walletIcon(wallet.iconName),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                wallet?.name ?? 'Pilih dompet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

double _parseMoney(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return double.tryParse(normalized) ?? 0;
}

Color _parseColor(String hex) {
  return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
}

IconData _walletIcon(String name) {
  return switch (name) {
    'cash' => Icons.payments_rounded,
    'mandiri' => Icons.account_balance_rounded,
    'bri' => Icons.account_balance_rounded,
    'bca' => Icons.account_balance_rounded,
    'ovo' => Icons.account_balance_wallet_rounded,
    'gopay' => Icons.motorcycle_rounded,
    'dana' => Icons.water_drop_rounded,
    'shopee' => Icons.shopping_bag_rounded,
    _ => Icons.account_balance_wallet_rounded,
  };
}
