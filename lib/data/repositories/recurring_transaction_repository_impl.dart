import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';
import '../daos/recurring_transaction_dao.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';

class RecurringTransactionRepositoryImpl implements RecurringTransactionRepository {
  final RecurringTransactionDao _dao;

  RecurringTransactionRepositoryImpl(this._dao);

  RecurringTransactionEntity _map(RecurringTransaction r) => RecurringTransactionEntity(
    id: r.id,
    amount: r.amount,
    note: r.note,
    type: r.type,
    categoryId: r.categoryId,
    frequency: r.frequency,
    nextDueDate: r.nextDueDate,
    isActive: r.isActive,
  );

  RecurringTransactionsCompanion _unmap(RecurringTransactionEntity r) => RecurringTransactionsCompanion(
    id: r.id == 0 ? const Value.absent() : Value(r.id),
    amount: Value(r.amount),
    note: Value(r.note),
    type: Value(r.type),
    categoryId: Value(r.categoryId),
    frequency: Value(r.frequency),
    nextDueDate: Value(r.nextDueDate),
    isActive: Value(r.isActive),
  );

  @override
  Stream<List<RecurringTransactionEntity>> watchAllRecurring() {
    return _dao.watchAllRecurring().map((list) => list.map(_map).toList());
  }

  @override
  Future<List<RecurringTransactionEntity>> getDueRecurring(DateTime now) async {
    final list = await _dao.getDueRecurring(now);
    return list.map(_map).toList();
  }

  @override
  Future<int> insertRecurring(RecurringTransactionEntity recurring) {
    return _dao.insertRecurring(_unmap(recurring));
  }

  @override
  Future<bool> updateRecurring(RecurringTransactionEntity recurring) {
    return _dao.updateRecurring(_unmap(recurring));
  }

  @override
  Future<void> toggleActive(int id, bool isActive) {
    return _dao.toggleActive(id, isActive);
  }
}
