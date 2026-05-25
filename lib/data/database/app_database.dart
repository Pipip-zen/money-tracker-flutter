import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../daos/category_dao.dart';
import '../daos/transaction_dao.dart';
import '../daos/budget_dao.dart';
import '../daos/recurring_transaction_dao.dart';
import '../daos/wallet_dao.dart';
import 'tables/wallets_table.dart';

// assuming that your file is called app_database.dart
// this will cause drift to generate a file called app_database.g.dart
part 'app_database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50)();
  IntColumn get icon => integer()();
  TextColumn get color => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()(); // 'income' | 'expense' | 'transfer'
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  @ReferenceName('transactionsFromWallet')
  IntColumn get walletId => integer().nullable().references(WalletTable, #id)();

  @ReferenceName('transactionsToWallet')
  IntColumn get toWalletId =>
      integer().nullable().references(WalletTable, #id)();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get limitAmount => real()();
  IntColumn get month => integer()(); // 1-12
  IntColumn get year => integer()();
}

class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  TextColumn get type => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get frequency => text()(); // 'daily' | 'weekly' | 'monthly'
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DriftDatabase(
  tables: [
    Categories,
    WalletTable,
    Transactions,
    Budgets,
    RecurringTransactions,
  ],
  daos: [
    CategoryDao,
    TransactionDao,
    BudgetDao,
    RecurringTransactionDao,
    WalletDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.fromExecutor(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _ensureDefaultWallet();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Because 'icon' was changed from String to int, we recreate tables
          // to clear old text data and fix FormatException parsing errors.
          await customStatement('PRAGMA foreign_keys = OFF');
          try {
            await m.drop(recurringTransactions);
            await m.drop(budgets);
            await m.drop(transactions);
            await m.drop(categories);
          } catch (_) {}
          await m.createAll();
          await customStatement('PRAGMA foreign_keys = ON');
          await _ensureDefaultWallet();
        } else {
          if (from < 3) {
            await m.createTable(walletTable);
          }

          if (from < 4) {
            final defaultWalletId = await _ensureDefaultWallet();
            await _addTransactionColumnIfMissing(
              m,
              'wallet_id',
              transactions.walletId,
            );
            await _addTransactionColumnIfMissing(
              m,
              'to_wallet_id',
              transactions.toWalletId,
            );
            await customStatement(
              'UPDATE transactions SET wallet_id = ? WHERE wallet_id IS NULL',
              [defaultWalletId],
            );
          }
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> resetAllData() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(budgets).go();
      await delete(recurringTransactions).go();
    });
  }

  Future<int> _ensureDefaultWallet() async {
    final existingDefault = await (select(
      walletTable,
    )..where((w) => w.isDefault.equals(true))).getSingleOrNull();
    if (existingDefault != null) return existingDefault.id;

    final now = DateTime.now();

    // Keep this id for next migration/task when existing transactions need a wallet_id.
    return into(walletTable).insert(
      WalletTableCompanion.insert(
        name: 'Kas Umum',
        type: const Value('cash'),
        iconName: const Value('wallet'),
        colorHex: const Value('#4CAF50'),
        isDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _addTransactionColumnIfMissing(
    Migrator migrator,
    String columnName,
    GeneratedColumn column,
  ) async {
    final columns = await customSelect('PRAGMA table_info(transactions)').get();
    final exists = columns.any((row) => row.data['name'] == columnName);
    if (!exists) {
      await migrator.addColumn(transactions, column);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Put the database file in the documents directory
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
