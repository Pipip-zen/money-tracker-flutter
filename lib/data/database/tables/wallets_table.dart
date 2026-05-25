import 'package:drift/drift.dart';

class WalletTable extends Table {
  @override
  String get tableName => 'wallets';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('custom'))();
  TextColumn get iconName =>
      text().named('icon_name').withDefault(const Constant('wallet'))();
  TextColumn get colorHex =>
      text().named('color_hex').withDefault(const Constant('#2196F3'))();
  RealColumn get initialBalance =>
      real().named('initial_balance').withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}
