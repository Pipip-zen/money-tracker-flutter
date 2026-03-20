import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Stream<List<TransactionEntity>> watchAllTransactions();
  Future<List<TransactionEntity>> getTransactionsByDateRange(DateTime from, DateTime to);
  Future<List<TransactionEntity>> getTransactionsByCategory(int categoryId);
  Future<int> insertTransaction(TransactionEntity transaction);
  Future<bool> updateTransaction(TransactionEntity transaction);
  Future<int> deleteTransaction(int id);
  Future<double> getTotalByType(String type, int month, int year);
}
