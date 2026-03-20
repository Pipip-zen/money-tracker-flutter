import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_providers.dart';

final combinedMonthlyTotalProvider = FutureProvider.family<({double income, double expense}), ({int month, int year})>((ref, param) async {
  final income = await ref.watch(monthlyTotalProvider((type: 'income', month: param.month, year: param.year)).future);
  final expense = await ref.watch(monthlyTotalProvider((type: 'expense', month: param.month, year: param.year)).future);
  return (income: income, expense: expense);
});

final currentBalanceProvider = FutureProvider<double>((ref) async {
  final txs = await ref.watch(transactionsStreamProvider.future);
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

final recentTransactionsProvider = Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  final txsAsync = ref.watch(transactionsStreamProvider);
  return txsAsync.whenData((txs) {
    final list = List<TransactionEntity>.from(txs)..sort((a, b) => b.date.compareTo(a.date));
    return list.take(10).toList();
  });
});
