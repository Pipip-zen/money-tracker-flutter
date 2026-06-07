import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<List<Wallet>> getAllWallets();
  Future<Wallet?> getWalletById(int id);
  Future<Wallet?> getDefaultWallet();
  Future<int> createWallet(Wallet wallet);
  Future<void> updateWallet(Wallet wallet);
  Future<void> setDefaultWallet(int id);
  Future<void> softDeleteWallet(int id);
  Future<void> cleanupStarterWalletsForOnboarding();
  Future<double> getWalletBalance(int walletId);
  Future<void> transfer({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    required DateTime date,
    String? note,
  });
  Stream<List<Wallet>> watchAllWallets();
  Stream<double> watchWalletBalance(int walletId);
}
