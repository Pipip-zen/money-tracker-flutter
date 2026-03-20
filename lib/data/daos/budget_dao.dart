import 'package:drift/drift.dart';
import '../database/app_database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Stream<List<Budget>> watchBudgetsByMonth(int month, int year) {
    return (select(budgets)..where((b) => b.month.equals(month) & b.year.equals(year))).watch();
  }

  Future<void> upsertBudget(BudgetsCompanion budget) {
    return into(budgets).insertOnConflictUpdate(budget);
  }

  Future<int> deleteBudget(int id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }
}
