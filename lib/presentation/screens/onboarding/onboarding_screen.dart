import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/wallet.dart';
import '../../providers/user_provider.dart';
import '../../providers/wallet_provider.dart';
import '../main_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _customWalletController = TextEditingController();
  final Set<String> _selectedWalletPresets = {'cash'};
  bool _isFormValid = false;

  static const _walletPresets = [
    _WalletPreset('cash', 'Cash', WalletType.cash, 'cash', '#4CAF50'),
    _WalletPreset('mandiri', 'Mandiri', WalletType.bank, 'mandiri', '#2196F3'),
    _WalletPreset('bca', 'BCA', WalletType.bank, 'bca', '#0D47A1'),
    _WalletPreset('bri', 'BRI', WalletType.bank, 'bri', '#1976D2'),
    _WalletPreset('ovo', 'OVO', WalletType.ewallet, 'ovo', '#673AB7'),
    _WalletPreset('gopay', 'GoPay', WalletType.ewallet, 'gopay', '#00BCD4'),
    _WalletPreset('dana', 'DANA', WalletType.ewallet, 'dana', '#2196F3'),
    _WalletPreset(
      'shopee',
      'ShopeePay',
      WalletType.ewallet,
      'shopee',
      '#FF9800',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _customWalletController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  void _submit() async {
    final hasWallet =
        _selectedWalletPresets.isNotEmpty ||
        _customWalletController.text.trim().isNotEmpty;
    if (_isFormValid && hasWallet) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();

      // Save user info
      await ref.read(userProvider.notifier).updateUser(name, email);
      await _createSelectedWallets();

      // Complete onboarding
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    }
  }

  Future<void> _createSelectedWallets() async {
    final repository = ref.read(walletRepositoryProvider);
    final now = DateTime.now();
    final selectedPresets = _walletPresets
        .where((preset) => _selectedWalletPresets.contains(preset.id))
        .toList();
    final wallets = [
      ...selectedPresets.map(
        (preset) => Wallet(
          id: 0,
          name: preset.name,
          type: preset.type,
          iconName: preset.iconName,
          colorHex: preset.colorHex,
          initialBalance: 0,
          currency: 'IDR',
          isDefault: false,
          isActive: true,
          sortOrder: selectedPresets.indexOf(preset),
          createdAt: now,
          updatedAt: now,
        ),
      ),
      if (_customWalletController.text.trim().isNotEmpty)
        Wallet(
          id: 0,
          name: _customWalletController.text.trim(),
          type: WalletType.custom,
          iconName: 'custom',
          colorHex: '#607D8B',
          initialBalance: 0,
          currency: 'IDR',
          isDefault: false,
          isActive: true,
          sortOrder: selectedPresets.length,
          createdAt: now,
          updatedAt: now,
        ),
    ];

    int? firstWalletId;
    for (final wallet in wallets) {
      final id = await repository.createWallet(wallet);
      firstWalletId ??= id;
    }

    if (firstWalletId != null) {
      await repository.setDefaultWallet(firstWalletId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              onChanged: _validateForm,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Selamat datang!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kenalan dulu sebelum mulai, yuk 👋',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Buat Dompet Pertama Anda',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih minimal satu dompet untuk mulai mencatat transaksi.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _walletPresets.map((preset) {
                      final selected = _selectedWalletPresets.contains(
                        preset.id,
                      );
                      return FilterChip(
                        selected: selected,
                        label: Text(preset.name),
                        avatar: Icon(_presetIcon(preset.iconName), size: 18),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedWalletPresets.add(preset.id);
                            } else {
                              _selectedWalletPresets.remove(preset.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customWalletController,
                    decoration: InputDecoration(
                      hintText: 'Dompet custom (opsional)',
                      prefixIcon: const Icon(Icons.wallet_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Nama lengkap kamu',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Nama harus diisi (min 2 karakter)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Email kamu',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email harus diisi';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (_isFormValid &&
                              (_selectedWalletPresets.isNotEmpty ||
                                  _customWalletController.text
                                      .trim()
                                      .isNotEmpty))
                          ? _submit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Mulai →',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletPreset {
  final String id;
  final String name;
  final WalletType type;
  final String iconName;
  final String colorHex;

  const _WalletPreset(
    this.id,
    this.name,
    this.type,
    this.iconName,
    this.colorHex,
  );
}

IconData _presetIcon(String name) {
  return switch (name) {
    'cash' => Icons.payments_rounded,
    'mandiri' => Icons.account_balance_rounded,
    'bri' => Icons.account_balance_rounded,
    'bca' => Icons.account_balance_rounded,
    'ovo' => Icons.account_balance_wallet_rounded,
    'gopay' => Icons.motorcycle_rounded,
    'dana' => Icons.water_drop_rounded,
    'shopee' => Icons.shopping_bag_rounded,
    _ => Icons.wallet_rounded,
  };
}
