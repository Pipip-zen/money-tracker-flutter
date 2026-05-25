import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/wallet.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/wallet/wallet_card.dart';
import '../transaction/transaction_form_screen.dart';
import 'wallet_detail_screen.dart';
import 'wallet_form_screen.dart';

class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet Saya'),
        actions: [
          IconButton(
            tooltip: 'Transfer antar dompet',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const TransactionFormScreen(initialType: 'transfer'),
              ),
            ),
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) => _WalletListContent(wallets: wallets),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Gagal memuat dompet')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalletFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WalletListContent extends ConsumerWidget {
  final List<Wallet> wallets;

  const _WalletListContent({required this.wallets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );
    double total = 0;
    final walletsWithBalance = wallets.map((wallet) {
      final balance = ref.watch(walletBalanceProvider(wallet.id)).valueOrNull;
      total += balance ?? wallet.currentBalance ?? wallet.initialBalance;
      return wallet.copyWith(currentBalance: balance);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Saldo',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (walletsWithBalance.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: Text('Belum ada dompet aktif')),
          )
        else
          ...walletsWithBalance.map(
            (wallet) => WalletCard(
              wallet: wallet,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalletDetailScreen(walletId: wallet.id),
                ),
              ),
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalletFormScreen(wallet: wallet),
                ),
              ),
              onDelete: () => _confirmDelete(context, ref, wallet),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dompet?'),
        content: Text('${wallet.name} akan dinonaktifkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(walletRepositoryProvider).softDeleteWallet(wallet.id);
  }
}
