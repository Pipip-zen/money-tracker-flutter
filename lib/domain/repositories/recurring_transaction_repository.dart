import '../entities/recurring_transaction_entity.dart';

abstract class RecurringTransactionRepository {
  Stream<List<RecurringTransactionEntity>> watchAllRecurring();
  Future<List<RecurringTransactionEntity>> getDueRecurring(DateTime now);
  Future<int> insertRecurring(RecurringTransactionEntity recurring);
  Future<bool> updateRecurring(RecurringTransactionEntity recurring);
  Future<void> toggleActive(int id, bool isActive);
}
