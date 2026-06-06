import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/wallet.dart';
import '../../providers/wallet_provider.dart';

class WalletFormScreen extends ConsumerStatefulWidget {
  final Wallet? wallet;

  const WalletFormScreen({super.key, this.wallet});

  @override
  ConsumerState<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends ConsumerState<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();

  late WalletType _type;
  late String _iconName;
  late String _colorHex;
  late bool _isDefault;

  bool get _isEdit => widget.wallet != null;

  static const _icons = [
    ('cash', Icons.payments_rounded, WalletType.cash),
    ('bank', Icons.account_balance_rounded, WalletType.bank),
    ('ewallet', Icons.account_balance_wallet_rounded, WalletType.ewallet),
  ];

  static const _colors = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#F44336',
    '#9C27B0',
    '#00BCD4',
    '#795548',
    '#607D8B',
    '#E91E63',
    '#1B4332',
  ];

  @override
  void initState() {
    super.initState();
    final wallet = widget.wallet;
    _nameController.text = wallet?.name ?? '';
    _initialBalanceController.text = wallet == null
        ? ''
        : NumberFormat.decimalPattern('id_ID').format(wallet.initialBalance);
    _type = wallet?.type ?? WalletType.cash;
    _iconName = wallet == null
        ? 'cash'
        : _normalizedIcon(wallet.iconName, wallet.type);
    _colorHex = wallet?.colorHex ?? '#2196F3';
    _isDefault = wallet?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final initialBalance = _parseMoney(_initialBalanceController.text);
    final wallet = Wallet(
      id: widget.wallet?.id ?? 0,
      name: _nameController.text.trim(),
      type: _type,
      iconName: _iconName,
      colorHex: _colorHex,
      initialBalance: _isEdit ? widget.wallet!.initialBalance : initialBalance,
      currency: widget.wallet?.currency ?? 'IDR',
      isDefault: _isDefault,
      isActive: widget.wallet?.isActive ?? true,
      sortOrder: widget.wallet?.sortOrder ?? 0,
      createdAt: widget.wallet?.createdAt ?? now,
      updatedAt: now,
    );

    final repository = ref.read(walletRepositoryProvider);

    try {
      final walletId = _isEdit
          ? widget.wallet!.id
          : await repository.createWallet(wallet);
      if (_isEdit) {
        await repository.updateWallet(wallet);
      }
      if (_isDefault) {
        await repository.setDefaultWallet(walletId);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan dompet')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Dompet' : 'Tambah Dompet')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Tipe', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WalletType.values.map((type) {
                  return ChoiceChip(
                    label: Text(_typeLabel(type)),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _icons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) {
                  final item = _icons[index];
                  final selected = _iconName == item.$1;
                  return InkWell(
                    onTap: () => setState(() {
                      _iconName = item.$1;
                      _type = item.$3;
                    }),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryGreen
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(item.$2, size: 22)],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Warna',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((hex) {
                  final color = _parseColor(hex);
                  final selected = _colorHex == hex;
                  return InkWell(
                    onTap: () => setState(() => _colorHex = hex),
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: color,
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _initialBalanceController,
                enabled: !_isEdit,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Saldo Awal',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isDefault,
                contentPadding: EdgeInsets.zero,
                title: const Text('Jadikan dompet default'),
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _typeLabel(WalletType type) {
  return switch (type) {
    WalletType.cash => 'Cash',
    WalletType.bank => 'Bank',
    WalletType.ewallet => 'E-Wallet',
    WalletType.custom => 'Custom',
  };
}

String _normalizedIcon(String iconName, WalletType type) {
  return switch (iconName) {
    'cash' => 'cash',
    'bank' || 'mandiri' || 'bri' || 'bca' => 'bank',
    'ewallet' || 'ovo' || 'gopay' || 'dana' || 'shopee' => 'ewallet',
    _ => switch (type) {
      WalletType.bank => 'bank',
      WalletType.ewallet => 'ewallet',
      _ => 'cash',
    },
  };
}

Color _parseColor(String hex) {
  return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
}

double _parseMoney(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return double.tryParse(normalized) ?? 0;
}
