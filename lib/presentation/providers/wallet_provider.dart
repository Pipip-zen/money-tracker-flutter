import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'database_provider.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WalletRepositoryImpl(db.walletDao);
});

final walletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletRepositoryProvider).watchAllWallets();
});

final walletBalanceProvider = StreamProvider.family<double, int>((
  ref,
  walletId,
) {
  return ref.watch(walletRepositoryProvider).watchWalletBalance(walletId);
});

final defaultWalletProvider = FutureProvider<Wallet?>((ref) {
  return ref.watch(walletRepositoryProvider).getDefaultWallet();
});

final selectedWalletIdProvider = StateProvider<int?>((ref) => null);

final selectedToWalletIdProvider = StateProvider<int?>((ref) => null);

class TransferNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> transfer({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(walletRepositoryProvider)
          .transfer(
            fromWalletId: fromWalletId,
            toWalletId: toWalletId,
            amount: amount,
            date: date,
            note: note,
          ),
    );
  }
}

final transferProvider = AsyncNotifierProvider<TransferNotifier, void>(
  TransferNotifier.new,
);
