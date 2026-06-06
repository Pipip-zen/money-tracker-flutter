import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/wallet_provider.dart';
import '../../screens/wallet/wallet_form_screen.dart';
import 'wallet_icon_mark.dart';

class WalletPickerSheet extends ConsumerWidget {
  final int? selectedWalletId;

  const WalletPickerSheet({super.key, this.selectedWalletId});

  static Future<int?> show(BuildContext context, {int? selectedWalletId}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          WalletPickerSheet(selectedWalletId: selectedWalletId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Dompet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            walletsAsync.when(
              data: (wallets) {
                if (wallets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Belum ada dompet aktif')),
                  );
                }

                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      final selected = wallet.id == selectedWalletId;
                      final color = _parseColor(wallet.colorHex);
                      final balance = ref
                          .watch(walletBalanceProvider(wallet.id))
                          .valueOrNull;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.14),
                          child: WalletIconMark(
                            iconName: wallet.iconName,
                            color: color,
                            size: 22,
                          ),
                        ),
                        title: Text(wallet.name),
                        subtitle: Text(
                          currencyFormat.format(
                            balance ??
                                wallet.currentBalance ??
                                wallet.initialBalance,
                          ),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, wallet.id),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Gagal memuat dompet')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletFormScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Buat Dompet Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
}
