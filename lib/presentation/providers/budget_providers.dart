import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/budget_entity.dart';
import 'repository_providers.dart';

class BudgetFilter {
  final int month;
  final int year;

  const BudgetFilter({required this.month, required this.year});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetFilter &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;
}

final budgetsProvider = StreamProvider.family<List<BudgetEntity>, BudgetFilter>((ref, filter) {
  return ref.watch(budgetRepositoryProvider).watchBudgetsByMonth(filter.month, filter.year);
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
