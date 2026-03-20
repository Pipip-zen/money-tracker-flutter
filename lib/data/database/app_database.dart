import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../daos/category_dao.dart';
import '../daos/transaction_dao.dart';
import '../daos/budget_dao.dart';
import '../daos/recurring_transaction_dao.dart';

// assuming that your file is called app_database.dart
// this will cause drift to generate a file called app_database.g.dart
part 'app_database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()(); // 'income' or 'expense'
  IntColumn get categoryId => integer().references(Categories, #id)();
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
  tables: [Categories, Transactions, Budgets, RecurringTransactions],
  daos: [CategoryDao, TransactionDao, BudgetDao, RecurringTransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Put the database file in the documents directory
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
