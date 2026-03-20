import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_providers.dart';

final combinedMonthlyTotalProvider = Provider.family<AsyncValue<({double income, double expense})>, ({int month, int year})>((ref, param) {
  final txsAsync = ref.watch(transactionsStreamProvider);
  return txsAsync.whenData((txs) {
    double income = 0;
    double expense = 0;
    for (final t in txs) {
      if (t.date.month == param.month && t.date.year == param.year) {
        if (t.type == 'income') {
          income += t.amount;
        } else if (t.type == 'expense') {
          expense += t.amount;
        }
      }
    }
    return (income: income, expense: expense);
  });
});

final currentBalanceProvider = Provider<AsyncValue<double>>((ref) {
  final txsAsync = ref.watch(transactionsStreamProvider);
  return txsAsync.whenData((txs) {
    double balance = 0.0;
    for (final t in txs) {
      if (t.type == 'income') {
        balance += t.amount;
      } else if (t.type == 'expense') {
        balance -= t.amount;
      }
    }
    return balance;
  });
});

final recentTransactionsProvider = Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  final txsAsync = ref.watch(transactionsStreamProvider);
  return txsAsync.whenData((txs) {
    final list = List<TransactionEntity>.from(txs)..sort((a, b) => b.date.compareTo(a.date));
    return list.take(10).toList();
  });
});
