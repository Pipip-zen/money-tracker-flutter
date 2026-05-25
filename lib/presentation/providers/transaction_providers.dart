import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/budget_reminder_service.dart';
import '../../domain/entities/transaction_entity.dart';
import 'budget_providers.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

final transactionsStreamProvider = StreamProvider<List<TransactionEntity>>((
  ref,
) {
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});

final transactionsByWalletProvider =
    StreamProvider.family<List<TransactionEntity>, int>((ref, walletId) {
      return ref
          .watch(transactionRepositoryProvider)
          .watchTransactionsByWallet(walletId);
    });

final transactionsByDateRangeProvider =
    Provider.family<
      AsyncValue<List<TransactionEntity>>,
      ({DateTime from, DateTime to})
    >((ref, param) {
      final asyncTxs = ref.watch(transactionsStreamProvider);
      return asyncTxs.whenData((txs) {
        return txs.where((t) {
          final isAfterOrSame = t.date.isAfter(
            param.from.subtract(const Duration(seconds: 1)),
          );
          final isBeforeOrSame = t.date.isBefore(
            param.to.add(const Duration(seconds: 1)),
          );
          return isAfterOrSame && isBeforeOrSame;
        }).toList()..sort((a, b) => b.date.compareTo(a.date));
      });
    });

final monthlyTotalProvider =
    Provider.family<AsyncValue<double>, ({String type, int month, int year})>((
      ref,
      param,
    ) {
      final asyncTxs = ref.watch(transactionsStreamProvider);
      return asyncTxs.whenData((txs) {
        return txs
            .where(
              (t) =>
                  t.type == param.type &&
                  t.type != 'transfer' &&
                  t.date.month == param.month &&
                  t.date.year == param.year,
            )
            .fold(0.0, (sum, t) => sum + t.amount);
      });
    });

class TransactionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addTransaction(TransactionEntity transaction) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(transactionRepositoryProvider)
          .insertTransaction(transaction);
      ref.invalidate(budgetsProvider);
      await BudgetReminderService(
        ref.read(databaseProvider),
      ).checkAndNotifyBudgets();
    });
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(transactionRepositoryProvider)
          .updateTransaction(transaction);
      ref.invalidate(budgetsProvider);
    });
  }

  Future<void> deleteTransaction(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      ref.invalidate(budgetsProvider);
    });
  }
}

final addTransactionProvider = AsyncNotifierProvider<TransactionNotifier, void>(
  TransactionNotifier.new,
);
