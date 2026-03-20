import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../daos/category_dao.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDao _dao;

  CategoryRepositoryImpl(this._dao);

  CategoryEntity _map(Category c) => CategoryEntity(
    id: c.id,
    name: c.name,
    icon: c.icon,
    color: c.color,
    type: c.type,
  );

  CategoriesCompanion _unmap(CategoryEntity c) => CategoriesCompanion(
    id: c.id == 0 ? const Value.absent() : Value(c.id),
    name: Value(c.name),
    icon: Value(c.icon),
    color: Value(c.color),
    type: Value(c.type),
  );

  @override
  Stream<List<CategoryEntity>> watchAllCategories() {
    return _dao.watchAllCategories().map((list) => list.map(_map).toList());
  }

  @override
  Future<List<CategoryEntity>> getCategoriesByType(String type) async {
    final list = await _dao.getCategoriesByType(type);
    return list.map(_map).toList();
  }

  @override
  Future<int> insertCategory(CategoryEntity category) {
    return _dao.insertCategory(_unmap(category));
  }

  @override
  Future<bool> updateCategory(CategoryEntity category) {
    return _dao.updateCategory(_unmap(category));
  }

  @override
  Future<int> deleteCategory(int id) {
    return _dao.deleteCategory(id);
  }
}
