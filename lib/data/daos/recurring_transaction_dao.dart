import 'package:drift/drift.dart';
import '../database/app_database.dart';

part 'recurring_transaction_dao.g.dart';

@DriftAccessor(tables: [RecurringTransactions])
class RecurringTransactionDao extends DatabaseAccessor<AppDatabase> with _$RecurringTransactionDaoMixin {
  RecurringTransactionDao(super.db);

  Stream<List<RecurringTransaction>> watchAllRecurring() => select(recurringTransactions).watch();

  Future<List<RecurringTransaction>> getDueRecurring(DateTime now) {
    return (select(recurringTransactions)
      ..where((r) => r.nextDueDate.isSmallerOrEqualValue(now) & r.isActive.equals(true)))
      .get();
  }

  Future<int> insertRecurring(RecurringTransactionsCompanion recurring) =>
      into(recurringTransactions).insert(recurring);

  Future<bool> updateRecurring(RecurringTransactionsCompanion recurring) =>
      update(recurringTransactions).replace(recurring);

  Future<void> toggleActive(int id, bool isActive) async {
    await (update(recurringTransactions)..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(isActive: Value(isActive)));
  }
}
