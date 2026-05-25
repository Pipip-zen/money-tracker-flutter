import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';

class BudgetReminderService {
  final AppDatabase _db;
  final FlutterLocalNotificationsPlugin _notifications;

  BudgetReminderService(
    this._db, {
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  Future<void> checkAndNotifyBudgets() async {
    final now = DateTime.now();
    final budgets = await (_db.select(
      _db.budgets,
    )..where((b) => b.month.equals(now.month) & b.year.equals(now.year))).get();
    if (budgets.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await _initializeNotifications();

    final categories = await _db.categoryDao.getAllCategories();
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    for (final budget in budgets) {
      if (budget.limitAmount <= 0) continue;

      final transactions = await _db.transactionDao.getTransactionsByCategory(
        budget.categoryId,
      );
      final spent = transactions
          .where(
            (tx) =>
                tx.type == 'expense' &&
                tx.date.month == budget.month &&
                tx.date.year == budget.year,
          )
          .fold<double>(0, (sum, tx) => sum + tx.amount);

      final percentage = spent / budget.limitAmount;
      if (percentage < 0.8) continue;

      final dateKey = DateFormat('yyyy-MM-dd').format(now);
      final prefKey = 'budget_notif_${budget.id}_$dateKey';
      final sentLevel = prefs.getString(prefKey);
      final categoryName =
          categoriesById[budget.categoryId]?.name ?? 'Kategori';

      if (percentage >= 1) {
        if (sentLevel == '100') continue;

        final over = spent - budget.limitAmount;
        await _showNotification(
          id: budget.id * 10 + 2,
          title: 'Budget terlampaui',
          body:
              'Budget $categoryName sudah melebihi batas! Terpakai ${_currency.format(over)} lebih.',
        );
        await prefs.setString(prefKey, '100');
      } else {
        if (sentLevel != null) continue;

        final remaining = budget.limitAmount - spent;
        await _showNotification(
          id: budget.id * 10 + 1,
          title: 'Budget hampir habis',
          body:
              'Budget $categoryName sudah terpakai 80%. Sisa ${_currency.format(remaining)}.',
        );
        await prefs.setString(prefKey, '80');
      }
    }
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _notifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) {
    const details = AndroidNotificationDetails(
      'recurring_channel',
      'Transaksi Rutin',
      channelDescription: 'Notifikasi transaksi rutin otomatis',
      importance: Importance.high,
      priority: Priority.high,
    );

    return _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: details),
    );
  }

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
}
