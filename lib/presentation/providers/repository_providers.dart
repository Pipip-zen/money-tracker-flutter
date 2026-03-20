import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/recurring_transaction_repository_impl.dart';
import 'database_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepositoryImpl(db.categoryDao);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepositoryImpl(db.transactionDao, db.categoryDao);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetRepositoryImpl(db.budgetDao, db.transactionDao);
});

final recurringRepositoryProvider = Provider<RecurringTransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RecurringTransactionRepositoryImpl(db.recurringTransactionDao);
});
