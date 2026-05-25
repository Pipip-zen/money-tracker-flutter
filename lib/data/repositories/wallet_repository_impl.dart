import 'package:drift/drift.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../daos/wallet_dao.dart';
import '../database/app_database.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletDao _walletDao;

  WalletRepositoryImpl(this._walletDao);

  @override
  Future<int> createWallet(Wallet wallet) {
    return _walletDao.insertWallet(_unmap(wallet));
  }

  @override
  Future<List<Wallet>> getAllWallets() async {
    final wallets = await _walletDao.getAllWallets();
    return Future.wait(wallets.map(_mapWithBalance));
  }

  @override
  Future<Wallet?> getDefaultWallet() async {
    final wallet = await _walletDao.getDefaultWallet();
    return wallet == null ? null : _mapWithBalance(wallet);
  }

  @override
  Future<Wallet?> getWalletById(int id) async {
    final wallet = await _walletDao.getWalletById(id);
    return wallet == null ? null : _mapWithBalance(wallet);
  }

  @override
  Future<double> getWalletBalance(int walletId) {
    return _walletDao.getWalletBalance(walletId);
  }

  @override
  Future<void> setDefaultWallet(int id) {
    return _walletDao.setDefaultWallet(id);
  }

  @override
  Future<void> softDeleteWallet(int id) async {
    await _walletDao.softDeleteWallet(id);
  }

  @override
  Future<void> updateWallet(Wallet wallet) async {
    await _walletDao.updateWallet(_unmap(wallet));
  }

  @override
  Future<void> transfer({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    if (fromWalletId == toWalletId) {
      throw ArgumentError('Cannot transfer to the same wallet.');
    }

    if (amount <= 0) {
      throw ArgumentError('Transfer amount must be greater than zero.');
    }

    final fromWallet = await _walletDao.getWalletById(fromWalletId);
    if (fromWallet == null || !fromWallet.isActive) {
      throw StateError('Source wallet is not active.');
    }

    final toWallet = await _walletDao.getWalletById(toWalletId);
    if (toWallet == null || !toWallet.isActive) {
      throw StateError('Destination wallet is not active.');
    }

    await _walletDao.insertTransferTransaction(
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      date: date,
      note: note,
    );
  }

  @override
  Stream<List<Wallet>> watchAllWallets() {
    return _walletDao.watchAllWallets().asyncMap(
      (wallets) => Future.wait(wallets.map(_mapWithBalance)),
    );
  }

  @override
  Stream<double> watchWalletBalance(int walletId) {
    return _walletDao.watchWalletBalance(walletId);
  }

  Future<Wallet> _mapWithBalance(WalletTableData wallet) async {
    final balance = await _walletDao.getWalletBalance(wallet.id);
    return _map(wallet, currentBalance: balance);
  }

  Wallet _map(WalletTableData wallet, {double? currentBalance}) {
    return Wallet(
      id: wallet.id,
      name: wallet.name,
      type: _walletTypeFromString(wallet.type),
      iconName: wallet.iconName,
      colorHex: wallet.colorHex,
      initialBalance: wallet.initialBalance,
      currency: wallet.currency,
      isDefault: wallet.isDefault,
      isActive: wallet.isActive,
      sortOrder: wallet.sortOrder,
      createdAt: wallet.createdAt,
      updatedAt: wallet.updatedAt,
      currentBalance: currentBalance,
    );
  }

  WalletTableCompanion _unmap(Wallet wallet) {
    return WalletTableCompanion(
      id: wallet.id == 0 ? const Value.absent() : Value(wallet.id),
      name: Value(wallet.name),
      type: Value(wallet.type.name),
      iconName: Value(wallet.iconName),
      colorHex: Value(wallet.colorHex),
      initialBalance: Value(wallet.initialBalance),
      currency: Value(wallet.currency),
      isDefault: Value(wallet.isDefault),
      isActive: Value(wallet.isActive),
      sortOrder: Value(wallet.sortOrder),
      createdAt: Value(wallet.createdAt),
      updatedAt: Value(wallet.updatedAt),
    );
  }

  WalletType _walletTypeFromString(String value) {
    return WalletType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => WalletType.custom,
    );
  }
}
