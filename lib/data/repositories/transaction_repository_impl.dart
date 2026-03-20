import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../daos/transaction_dao.dart';
import '../daos/category_dao.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _transactionDao;
  final CategoryDao _categoryDao;

  TransactionRepositoryImpl(this._transactionDao, this._categoryDao);

  Future<List<TransactionEntity>> _mapList(List<Transaction> list) async {
    final categories = await _categoryDao.getAllCategories();
    final categoryMap = {for (var c in categories) c.id: c};
    
    return list.map((t) {
      final category = categoryMap[t.categoryId];
      return TransactionEntity(
        id: t.id,
        amount: t.amount,
        note: t.note,
        date: t.date,
        type: t.type,
        categoryId: t.categoryId,
        categoryName: category?.name ?? 'Unknown',
        categoryIcon: category?.icon ?? '📦',
        categoryColor: category?.color ?? '#000000',
      );
    }).toList();
  }

  TransactionsCompanion _unmap(TransactionEntity t) => TransactionsCompanion(
    id: t.id == 0 ? const Value.absent() : Value(t.id),
    amount: Value(t.amount),
    note: Value(t.note),
    date: Value(t.date),
    type: Value(t.type),
    categoryId: Value(t.categoryId),
  );

  @override
  Stream<List<TransactionEntity>> watchAllTransactions() {
    return _transactionDao.watchAllTransactions().asyncMap((list) => _mapList(list));
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByDateRange(DateTime from, DateTime to) async {
    final list = await _transactionDao.getTransactionsByDateRange(from, to);
    return _mapList(list);
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByCategory(int categoryId) async {
    final list = await _transactionDao.getTransactionsByCategory(categoryId);
    return _mapList(list);
  }

  @override
  Future<int> insertTransaction(TransactionEntity transaction) {
    return _transactionDao.insertTransaction(_unmap(transaction));
  }

  @override
  Future<bool> updateTransaction(TransactionEntity transaction) {
    return _transactionDao.updateTransaction(_unmap(transaction));
  }

  @override
  Future<int> deleteTransaction(int id) {
    return _transactionDao.deleteTransaction(id);
  }

  @override
  Future<double> getTotalByType(String type, int month, int year) {
    return _transactionDao.getTotalByType(type, month, year);
  }
}
