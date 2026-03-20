import 'package:shared_preferences/shared_preferences.dart';
import 'app_database.dart';

class DatabaseSeeder {
  static const String _isSeededKey = 'is_seeded';

  static Future<void> seedCategories(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool(_isSeededKey) ?? false;

    if (isSeeded) return;

    // Expense categories
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Makan',
      icon: '🍽',
      color: '#FF6B6B',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Transport',
      icon: '🚗',
      color: '#4ECDC4',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Hiburan',
      icon: '🎮',
      color: '#45B7D1',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Kesehatan',
      icon: '💊',
      color: '#96CEB4',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Belanja',
      icon: '🛍',
      color: '#FFEAA7',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Tagihan',
      icon: '📄',
      color: '#DDA0DD',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Lainnya',
      icon: '📦',
      color: '#B0B0B0',
      type: 'expense',
    ));

    // Income categories
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Gaji',
      icon: '💼',
      color: '#2ECC71',
      type: 'income',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Freelance',
      icon: '💻',
      color: '#3498DB',
      type: 'income',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Investasi',
      icon: '📈',
      color: '#F39C12',
      type: 'income',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Lainnya',
      icon: '💰',
      color: '#1ABC9C',
      type: 'income',
    ));

    await prefs.setBool(_isSeededKey, true);
  }
}
