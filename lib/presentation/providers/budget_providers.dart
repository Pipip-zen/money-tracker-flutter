import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/budget_entity.dart';
import 'repository_providers.dart';

final budgetsProvider = StreamProvider.family<List<BudgetEntity>, ({int month, int year})>((ref, param) {
  return ref.watch(budgetRepositoryProvider).watchBudgetsByMonth(param.month, param.year);
});

class BudgetNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> upsertBudget(BudgetEntity budget) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(budgetRepositoryProvider).upsertBudget(budget));
  }
  
  Future<void> deleteBudget(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(budgetRepositoryProvider).deleteBudget(id));
  }
}

final upsertBudgetProvider = AsyncNotifierProvider<BudgetNotifier, void>(BudgetNotifier.new);
