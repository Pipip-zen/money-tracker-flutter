import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import 'repository_providers.dart';

final transactionsStreamProvider = StreamProvider<List<TransactionEntity>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});

final transactionsByDateRangeProvider = FutureProvider.family<List<TransactionEntity>, ({DateTime from, DateTime to})>((ref, param) {
  return ref.watch(transactionRepositoryProvider).getTransactionsByDateRange(param.from, param.to);
});

final monthlyTotalProvider = FutureProvider.family<double, ({String type, int month, int year})>((ref, param) {
  return ref.watch(transactionRepositoryProvider).getTotalByType(param.type, param.month, param.year);
});

class TransactionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addTransaction(TransactionEntity transaction) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(transactionRepositoryProvider).insertTransaction(transaction));
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(transactionRepositoryProvider).updateTransaction(transaction));
  }

  Future<void> deleteTransaction(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(transactionRepositoryProvider).deleteTransaction(id));
  }
}

final addTransactionProvider = AsyncNotifierProvider<TransactionNotifier, void>(TransactionNotifier.new);
