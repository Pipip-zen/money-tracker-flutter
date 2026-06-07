import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/wallet.dart';
import '../../providers/user_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/wallet/wallet_icon_mark.dart';
import '../main_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _walletFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _customWalletController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  String? _selectedWalletPresetId;
  int _step = 0;
  bool _saving = false;

  static const _walletPresets = [
    _WalletPreset('cash', 'Cash', WalletType.cash, 'cash', '#4CAF50'),
    _WalletPreset('mandiri', 'Mandiri', WalletType.bank, 'mandiri', '#2196F3'),
    _WalletPreset('bca', 'BCA', WalletType.bank, 'bca', '#0D47A1'),
    _WalletPreset('bri', 'BRI', WalletType.bank, 'bri', '#1976D2'),
    _WalletPreset('ovo', 'OVO', WalletType.ewallet, 'ovo', '#673AB7'),
    _WalletPreset('gopay', 'GoPay', WalletType.ewallet, 'gopay', '#00BCD4'),
    _WalletPreset('dana', 'DANA', WalletType.ewallet, 'dana', '#118EEA'),
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
    _initialBalanceController.dispose();
    super.dispose();
  }

  void _goToWalletStep() {
    final valid = _profileFormKey.currentState?.validate() ?? false;
    if (!valid) return;
    setState(() => _step = 1);
  }

  Future<void> _finish({required bool createWallets}) async {
    if (_saving) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(userProvider.notifier)
          .updateUser(
            _nameController.text.trim(),
            _emailController.text.trim(),
          );

      if (createWallets) {
        final valid = _walletFormKey.currentState?.validate() ?? false;
        if (!valid || !_hasWalletSelection) {
          setState(() => _saving = false);
          return;
        }
        await _createFirstWallet();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyelesaikan onboarding')),
      );
    }
  }

  Future<void> _createFirstWallet() async {
    final repository = ref.read(walletRepositoryProvider);
    final now = DateTime.now();
    final customWalletName = _customWalletController.text.trim();
    final preset = _selectedWalletPreset;
    final initialBalance = _parseMoney(_initialBalanceController.text);

    await repository.cleanupStarterWalletsForOnboarding();

    final wallet = Wallet(
      id: 0,
      name: customWalletName.isNotEmpty ? customWalletName : preset!.name,
      type: customWalletName.isNotEmpty ? WalletType.custom : preset!.type,
      iconName: customWalletName.isNotEmpty ? 'custom' : preset!.iconName,
      colorHex: customWalletName.isNotEmpty ? '#607D8B' : preset!.colorHex,
      initialBalance: initialBalance,
      currency: 'IDR',
      isDefault: true,
      isActive: true,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    final walletId = await repository.createWallet(wallet);
    await repository.setDefaultWallet(walletId);
  }

  bool get _hasWalletSelection =>
      _selectedWalletPresetId != null ||
      _customWalletController.text.trim().isNotEmpty;

  _WalletPreset? get _selectedWalletPreset {
    final id = _selectedWalletPresetId;
    if (id == null) return null;
    for (final preset in _walletPresets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _step == 0 ? _buildProfileStep() : _buildWalletStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      children: [
        Image.asset('assets/icon/icon.png', width: 82, height: 82),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Form(
      key: _profileFormKey,
      child: Column(
        key: const ValueKey('profile-step'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(
            'Selamat datang di Catetin',
            'Masukkan profil dulu biar catatan keuangan terasa personal.',
          ),
          const SizedBox(height: 36),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nama',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Nama minimal 2 karakter';
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
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email wajib diisi';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Format email tidak valid';
              }
              return null;
            },
            onFieldSubmitted: (_) => _goToWalletStep(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _goToWalletStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lanjut'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStep() {
    return Form(
      key: _walletFormKey,
      child: Column(
        key: const ValueKey('wallet-step'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(
            'Buat dompet pertama',
            'Pilih satu dompet dan isi saldo awal.',
          ),
          const SizedBox(height: 30),
          FormField<String>(
            validator: (_) {
              if (!_hasWalletSelection) {
                return 'Pilih satu dompet atau isi dompet custom';
              }
              return null;
            },
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _walletPresets.map((preset) {
                      final selected = _selectedWalletPresetId == preset.id;
                      final color = _parseColor(preset.colorHex);
                      return ChoiceChip(
                        selected: selected,
                        label: Text(preset.name),
                        avatar: WalletIconMark(
                          iconName: preset.iconName,
                          color: color,
                          size: 18,
                        ),
                        onSelected: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedWalletPresetId = value
                                      ? preset.id
                                      : null;
                                  if (value) _customWalletController.clear();
                                });
                                field.didChange(_selectedWalletPresetId);
                              },
                      );
                    }).toList(),
                  ),
                  if (field.hasError) ...[
                    const SizedBox(height: 8),
                    Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customWalletController,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: 'Dompet custom',
              hintText: 'Contoh: Tabungan pribadi',
              prefixIcon: const Icon(Icons.wallet_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                if (value.trim().isNotEmpty) {
                  _selectedWalletPresetId = null;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _initialBalanceController,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Saldo awal',
              prefixText: 'Rp ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Saldo awal wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _finish(createWallets: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mulai'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _saving ? null : () => setState(() => _step = 0),
            child: const Text('Kembali'),
          ),
        ],
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

Color _parseColor(String hex) {
  return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
}

double _parseMoney(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return double.tryParse(normalized) ?? 0;
}
