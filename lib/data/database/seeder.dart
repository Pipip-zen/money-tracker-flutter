import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_database.dart';

class DatabaseSeeder {
  static const String _isSeededKey = 'is_seeded_v2';

  static Future<void> seedCategories(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool(_isSeededKey) ?? false;

    if (isSeeded) return;

    // Expense categories
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Makan',
      icon: Icons.restaurant.codePoint,
      color: '#FF6B6B',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Transport',
      icon: Icons.directions_car.codePoint,
      color: '#4ECDC4',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Hiburan',
      icon: Icons.movie.codePoint,
      color: '#45B7D1',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Kesehatan',
      icon: Icons.local_hospital.codePoint,
      color: '#96CEB4',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Belanja',
      icon: Icons.shopping_bag.codePoint,
      color: '#FFEAA7',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Tagihan',
      icon: Icons.receipt_long.codePoint,
      color: '#DDA0DD',
      type: 'expense',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Lainnya',
      icon: Icons.more_horiz.codePoint,
      color: '#B0B0B0',
      type: 'expense',
    ));

    // Income categories
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Gaji',
      icon: Icons.monetization_on.codePoint,
      color: '#2ECC71',
      type: 'income',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Freelance',
      icon: Icons.laptop.codePoint,
      color: '#3498DB',
      type: 'income',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Investasi',
      icon: Icons.trending_up.codePoint,
      color: '#F39C12',
      type: 'income',
    ));
    await db.categoryDao.insertCategory(CategoriesCompanion.insert(
      name: 'Lainnya',
      icon: Icons.more_horiz.codePoint,
      color: '#1ABC9C',
      type: 'income',
    ));

    await prefs.setBool(_isSeededKey, true);
  }
}
