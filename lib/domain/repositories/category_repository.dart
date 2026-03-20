import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Stream<List<CategoryEntity>> watchAllCategories();
  Future<List<CategoryEntity>> getCategoriesByType(String type);
  Future<int> insertCategory(CategoryEntity category);
  Future<bool> updateCategory(CategoryEntity category);
  Future<int> deleteCategory(int id);
}
