import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/wallet.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WalletCard({
    super.key,
    required this.wallet,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(wallet.colorHex);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${wallet.currency} ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(_walletIcon(wallet.iconName), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wallet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (wallet.isDefault)
                          Chip(
                            label: const Text('Default'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _walletTypeLabel(wallet.type),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(
                        wallet.currentBalance ?? wallet.initialBalance,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final normalized = hex.replaceAll('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
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
