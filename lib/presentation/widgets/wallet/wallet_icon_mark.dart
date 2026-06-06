import 'package:flutter/material.dart';

class WalletIconMark extends StatelessWidget {
  final String iconName;
  final Color? color;
  final double size;

  const WalletIconMark({
    super.key,
    required this.iconName,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color;

    if (iconName == 'dana') {
      return SizedBox.square(
        dimension: size,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'DANA',
              style: TextStyle(
                color: iconColor,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      );
    }

    return Icon(_walletIcon(iconName), color: iconColor, size: size);
  }
}

IconData _walletIcon(String name) {
  return switch (name) {
    'cash' => Icons.payments_rounded,
    'bank' => Icons.account_balance_rounded,
    'mandiri' => Icons.account_balance_rounded,
    'bri' => Icons.account_balance_rounded,
    'bca' => Icons.account_balance_rounded,
    'ewallet' => Icons.account_balance_wallet_rounded,
    'ovo' => Icons.account_balance_wallet_rounded,
    'gopay' => Icons.motorcycle_rounded,
    'dana' => Icons.account_balance_wallet_rounded,
    'shopee' => Icons.shopping_bag_rounded,
    _ => Icons.account_balance_wallet_rounded,
  };
}
