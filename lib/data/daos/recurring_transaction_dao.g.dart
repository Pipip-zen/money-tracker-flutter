// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringTransactionDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $WalletTableTable get walletTable => attachedDatabase.walletTable;
  $RecurringTransactionsTable get recurringTransactions =>
      attachedDatabase.recurringTransactions;
  RecurringTransactionDaoManager get managers =>
      RecurringTransactionDaoManager(this);
}

class RecurringTransactionDaoManager {
  final _$RecurringTransactionDaoMixin _db;
  RecurringTransactionDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$WalletTableTableTableManager get walletTable =>
      $$WalletTableTableTableManager(_db.attachedDatabase, _db.walletTable);
  $$RecurringTransactionsTableTableManager get recurringTransactions =>
      $$RecurringTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.recurringTransactions,
      );
}
