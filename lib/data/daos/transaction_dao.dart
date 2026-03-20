import 'package:drift/drift.dart';
import '../database/app_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<Transaction>> watchAllTransactions() => select(transactions).watch();

  Future<List<Transaction>> getTransactionsByDateRange(DateTime from, DateTime to) {
    return (select(transactions)
      ..where((t) => t.date.isBetweenValues(from, to)))
      .get();
  }

  Future<List<Transaction>> getTransactionsByCategory(int categoryId) {
    return (select(transactions)
      ..where((t) => t.categoryId.equals(categoryId)))
      .get();
  }

  Future<int> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);

  Future<bool> updateTransaction(TransactionsCompanion transaction) =>
      update(transactions).replace(transaction);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<double> getTotalByType(String type, int month, int year) async {
    final amountExp = transactions.amount.sum();
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final query = selectOnly(transactions)
      ..addColumns([amountExp])
      ..where(transactions.type.equals(type) & transactions.date.isBetweenValues(startDate, endDate));
      
    final result = await query.map((row) => row.read(amountExp)).getSingleOrNull();
    return result ?? 0.0;
  }
}
