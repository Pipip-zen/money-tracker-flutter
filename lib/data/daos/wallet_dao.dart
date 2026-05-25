import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/wallets_table.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [WalletTable, Transactions])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  Future<int> insertWallet(WalletTableCompanion wallet) =>
      into(walletTable).insert(wallet);

  Future<bool> updateWallet(WalletTableCompanion wallet) =>
      update(walletTable).replace(wallet);

  Future<WalletTableData?> getWalletById(int id) =>
      (select(walletTable)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<WalletTableData?> getDefaultWallet() => (select(
    walletTable,
  )..where((w) => w.isDefault.equals(true))).getSingleOrNull();

  Future<List<WalletTableData>> getAllWallets() {
    return (select(walletTable)
          ..where((w) => w.isActive.equals(true))
          ..orderBy([
            (w) => OrderingTerm(expression: w.sortOrder),
            (w) => OrderingTerm(expression: w.name),
          ]))
        .get();
  }

  Stream<List<WalletTableData>> watchAllWallets() {
    return (select(walletTable)
          ..where((w) => w.isActive.equals(true))
          ..orderBy([
            (w) => OrderingTerm(expression: w.sortOrder),
            (w) => OrderingTerm(expression: w.name),
          ]))
        .watch();
  }

  Future<int> softDeleteWallet(int id) {
    return (update(walletTable)..where((w) => w.id.equals(id))).write(
      WalletTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setDefaultWallet(int id) {
    return transaction(() async {
      await update(walletTable).write(
        WalletTableCompanion(
          isDefault: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (update(walletTable)..where((w) => w.id.equals(id))).write(
        WalletTableCompanion(
          isDefault: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<int> insertTransferTransaction({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    required DateTime date,
    String? note,
  }) {
    return into(transactions).insert(
      TransactionsCompanion.insert(
        amount: amount,
        note: Value(note),
        date: date,
        type: 'transfer',
        categoryId: const Value(null),
        walletId: Value(fromWalletId),
        toWalletId: Value(toWalletId),
      ),
    );
  }

  Future<double> getWalletBalance(int walletId) async {
    final row = await _walletBalanceQuery(walletId).getSingle();
    return row.read<double>('balance');
  }

  Stream<double> watchWalletBalance(int walletId) {
    return _walletBalanceQuery(
      walletId,
    ).watchSingle().map((row) => row.read<double>('balance'));
  }

  Selectable<QueryRow> _walletBalanceQuery(int walletId) {
    return customSelect(
      '''
      SELECT
        COALESCE(w.initial_balance, 0) +
        COALESCE(SUM(CASE
          WHEN t.wallet_id = w.id AND t.type = 'income' THEN t.amount
          WHEN t.wallet_id = w.id AND t.type = 'expense' THEN -t.amount
          WHEN t.wallet_id = w.id AND t.type = 'transfer' THEN -t.amount
          WHEN t.to_wallet_id = w.id AND t.type = 'transfer' THEN t.amount
          ELSE 0
        END), 0) AS balance
      FROM wallets w
      LEFT JOIN transactions t
        ON t.wallet_id = w.id OR t.to_wallet_id = w.id
      WHERE w.id = ?
      GROUP BY w.id, w.initial_balance
      ''',
      variables: [Variable<int>(walletId)],
      readsFrom: {walletTable, transactions},
    );
  }
}
