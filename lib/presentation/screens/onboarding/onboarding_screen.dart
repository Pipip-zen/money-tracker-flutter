import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _customWalletController = TextEditingController();
  final Set<String> _selectedWalletPresets = {};
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
        await _createSelectedWallets();
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

  bool get _hasWalletSelection =>
      _selectedWalletPresets.isNotEmpty ||
      _customWalletController.text.trim().isNotEmpty;

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
    return Column(
      key: const ValueKey('wallet-step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(
          'Buat dompet pertama',
          'Pilih dompet yang kamu pakai. Bisa dilewati dan dibuat nanti.',
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _walletPresets.map((preset) {
            final selected = _selectedWalletPresets.contains(preset.id);
            final color = _parseColor(preset.colorHex);
            return FilterChip(
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
          enabled: !_saving,
          decoration: InputDecoration(
            labelText: 'Dompet custom',
            hintText: 'Contoh: Tabungan pribadi',
            prefixIcon: const Icon(Icons.wallet_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () => _finish(createWallets: _hasWalletSelection),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_hasWalletSelection ? 'Mulai' : 'Lewati dan mulai'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _saving ? null : () => setState(() => _step = 0),
          child: const Text('Kembali'),
        ),
      ],
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
