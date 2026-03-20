import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import 'repository_providers.dart';

final categoriesStreamProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAllCategories();
});

final categoriesByTypeProvider = Provider.family<AsyncValue<List<CategoryEntity>>, String>((ref, type) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  return categoriesAsync.whenData((categories) => categories.where((c) => c.type == type).toList());
});
