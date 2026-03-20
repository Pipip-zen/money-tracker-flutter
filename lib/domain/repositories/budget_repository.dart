import '../entities/budget_entity.dart';

abstract class BudgetRepository {
  Stream<List<BudgetEntity>> watchBudgetsByMonth(int month, int year);
  Future<void> upsertBudget(BudgetEntity budget);
  Future<int> deleteBudget(int id);
}
