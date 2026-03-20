import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';

import '../../data/database/app_database.dart';

const String _kRecurringTaskName = 'com.moneytracker.recurring';
const String _kRecurringTaskTag = 'recurring_check';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

/// Call once at app startup after WidgetsFlutterBinding.ensureInitialized().
Future<void> initRecurringService() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notifications.initialize(
    settings: const InitializationSettings(android: androidSettings),
  );

  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    _kRecurringTaskName,
    _kRecurringTaskTag,
    frequency: const Duration(hours: 24),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

/// WorkManager callback — runs in a separate isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _kRecurringTaskTag) {
      await _processRecurring();
    }
    return true;
  });
}

Future<void> _processRecurring() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));

  final db = _openIsolateDb(dbFile);

  try {
    final now = DateTime.now();
    final dueItems = await db.recurringTransactionDao.getDueRecurring(now);
    int count = 0;

    for (final item in dueItems) {
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          amount: Value(item.amount),
          note: Value(item.note),
          date: Value(now),
          type: Value(item.type),
          categoryId: Value(item.categoryId),
        ),
      );

      final nextDue = _nextDueDate(item.nextDueDate, item.frequency);

      await db.recurringTransactionDao.updateRecurring(
        RecurringTransactionsCompanion(
          id: Value(item.id),
          amount: Value(item.amount),
          note: Value(item.note),
          type: Value(item.type),
          categoryId: Value(item.categoryId),
          frequency: Value(item.frequency),
          nextDueDate: Value(nextDue),
          isActive: Value(item.isActive),
        ),
      );
      count++;
    }

    if (count > 0) await _sendNotification(count);
  } finally {
    await db.close();
  }
}

AppDatabase _openIsolateDb(File file) {
  return AppDatabase.fromExecutor(NativeDatabase(file));
}

DateTime _nextDueDate(DateTime current, String frequency) {
  switch (frequency) {
    case 'daily':
      return current.add(const Duration(days: 1));
    case 'weekly':
      return current.add(const Duration(days: 7));
    case 'monthly':
    default:
      return DateTime(current.year, current.month + 1, current.day);
  }
}

Future<void> _sendNotification(int count) async {
  const details = AndroidNotificationDetails(
    'recurring_channel',
    'Transaksi Rutin',
    channelDescription: 'Notifikasi transaksi rutin otomatis',
    importance: Importance.high,
    priority: Priority.high,
  );

  await _notifications.show(
    id: 1001,
    title: '🔁 Transaksi Rutin Dicatat',
    body: '$count transaksi rutin berhasil ditambahkan secara otomatis.',
    notificationDetails: const NotificationDetails(android: details),
  );
}
