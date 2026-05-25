import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/wallet.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/wallet_provider.dart';
import '../transaction/transaction_form_screen.dart';
import 'wallet_form_screen.dart';

class WalletDetailScreen extends ConsumerWidget {
  final int walletId;

  const WalletDetailScreen({super.key, required this.walletId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

    return walletsAsync.when(
      data: (wallets) {
        final wallet = wallets.where((item) => item.id == walletId).firstOrNull;
        if (wallet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Dompet tidak ditemukan')),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(wallet.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WalletFormScreen(wallet: wallet),
                    ),
                  ),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Semua'),
                  Tab(text: 'Masuk'),
                  Tab(text: 'Keluar'),
                  Tab(text: 'Transfer'),
                ],
              ),
            ),
            body: Column(
              children: [
                _WalletHeader(wallet: wallet),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TransactionList(walletId: walletId, wallets: wallets),
                      _TransactionList(
                        walletId: walletId,
                        wallets: wallets,
                        type: 'income',
                      ),
                      _TransactionList(
                        walletId: walletId,
                        wallets: wallets,
                        type: 'expense',
                      ),
                      _TransactionList(
                        walletId: walletId,
                        wallets: wallets,
                        type: 'transfer',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TransactionFormScreen(initialWalletId: walletId),
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) =>
          const Scaffold(body: Center(child: Text('Gagal memuat dompet'))),
    );
  }
}

class _WalletHeader extends ConsumerWidget {
  final Wallet wallet;

  const _WalletHeader({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));
    final color = _parseColor(wallet.colorHex);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${wallet.currency} ',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(_walletIcon(wallet.iconName), color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _walletTypeLabel(wallet.type),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  balanceAsync.maybeWhen(
                    data: currencyFormat.format,
                    orElse: () => currencyFormat.format(
                      wallet.currentBalance ?? wallet.initialBalance,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  final int walletId;
  final List<Wallet> wallets;
  final String? type;

  const _TransactionList({
    required this.walletId,
    required this.wallets,
    this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsByWalletProvider(walletId));

    return transactionsAsync.when(
      data: (transactions) {
        final filtered = type == null
            ? transactions
            : transactions.where((tx) => tx.type == type).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Belum ada transaksi'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _TransactionTile(
              transaction: filtered[index],
              walletId: walletId,
              wallets: wallets,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Gagal memuat transaksi')),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final int walletId;
  final List<Wallet> wallets;

  const _TransactionTile({
    required this.transaction,
    required this.walletId,
    required this.wallets,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isIncome = transaction.type == 'income';
    final isExpense = transaction.type == 'expense';
    final isTransferOut =
        transaction.type == 'transfer' && transaction.walletId == walletId;
    final color = isIncome
        ? Colors.green
        : isExpense
        ? Colors.red
        : Colors.blue;
    final prefix = isIncome
        ? '+'
        : isExpense
        ? '-'
        : isTransferOut
        ? '-'
        : '+';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        title: Text(transaction.note ?? transaction.categoryName),
        subtitle: Text(
          '${DateFormat('dd MMM yyyy', 'id_ID').format(transaction.date)} • '
          '${_subtitle()}',
        ),
        trailing: Text(
          '$prefix${currencyFormat.format(transaction.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  String _subtitle() {
    if (transaction.type != 'transfer') {
      return transaction.categoryName;
    }

    if (transaction.walletId == walletId) {
      final toWallet = wallets
          .where((wallet) => wallet.id == transaction.toWalletId)
          .firstOrNull;
      return 'Transfer -> ${toWallet?.name ?? 'Dompet tujuan'}';
    }

    final fromWallet = wallets
        .where((wallet) => wallet.id == transaction.walletId)
        .firstOrNull;
    return 'Transfer <- ${fromWallet?.name ?? 'Dompet asal'}';
  }
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

String _walletTypeLabel(WalletType type) {
  return switch (type) {
    WalletType.cash => 'Cash',
    WalletType.bank => 'Bank',
    WalletType.ewallet => 'E-Wallet',
    WalletType.custom => 'Custom',
  };
}
