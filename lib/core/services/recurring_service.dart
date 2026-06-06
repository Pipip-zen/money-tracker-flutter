import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';

class RecurringService {
  static final RecurringService _instance = RecurringService._internal();
  factory RecurringService() => _instance;
  RecurringService._internal();

  Future<void> runCheck() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
    final db = AppDatabase.fromExecutor(NativeDatabase(dbFile));

    try {
      final now = DateTime.now();
      final dueItems = await db.recurringTransactionDao.getDueRecurring(now);

      for (final item in dueItems) {
        final defaultWallet = await db.walletDao.getDefaultWallet();
        final walletId = item.walletId ?? defaultWallet?.id;

        await db.transactionDao.insertTransaction(
          TransactionsCompanion(
            amount: Value(item.amount),
            note: Value(item.note),
            date: Value(now),
            type: Value(item.type),
            categoryId: Value(item.categoryId),
            walletId: Value(walletId),
          ),
        );

        await db.recurringTransactionDao.updateRecurring(
          RecurringTransactionsCompanion(
            id: Value(item.id),
            amount: Value(item.amount),
            note: Value(item.note),
            type: Value(item.type),
            categoryId: Value(item.categoryId),
            walletId: Value(item.walletId),
            frequency: Value(item.frequency),
            nextDueDate: Value(_nextDueDate(item.nextDueDate, item.frequency)),
            isActive: Value(item.isActive),
          ),
        );
      }
    } finally {
      await db.close();
    }
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
}
