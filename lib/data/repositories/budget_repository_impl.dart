import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../daos/budget_dao.dart';
import '../daos/transaction_dao.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDao _budgetDao;
  final TransactionDao _transactionDao;

  BudgetRepositoryImpl(this._budgetDao, this._transactionDao);

  Future<BudgetEntity> _map(Budget b) async {
    final txs = await _transactionDao.getTransactionsByCategory(b.categoryId);
    final spent = txs
        .where((t) => t.date.month == b.month && t.date.year == b.year && t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    return BudgetEntity(
      id: b.id,
      categoryId: b.categoryId,
      limitAmount: b.limitAmount,
      month: b.month,
      year: b.year,
      spentAmount: spent,
    );
  }

  BudgetsCompanion _unmap(BudgetEntity b) => BudgetsCompanion(
    id: b.id == 0 ? const Value.absent() : Value(b.id),
    categoryId: Value(b.categoryId),
    limitAmount: Value(b.limitAmount),
    month: Value(b.month),
    year: Value(b.year),
  );

  @override
  Stream<List<BudgetEntity>> watchBudgetsByMonth(int month, int year) {
    return _budgetDao.watchBudgetsByMonth(month, year).asyncMap((list) async {
      final List<BudgetEntity> result = [];
      for (final b in list) {
        result.add(await _map(b));
      }
      return result;
    });
  }

  @override
  Future<void> upsertBudget(BudgetEntity budget) {
    return _budgetDao.upsertBudget(_unmap(budget));
  }

  @override
  Future<int> deleteBudget(int id) {
    return _budgetDao.deleteBudget(id);
  }
}
