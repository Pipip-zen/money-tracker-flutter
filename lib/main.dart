import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/database/seeder.dart';
import 'presentation/screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  final db = AppDatabase();
  GetIt.instance.registerSingleton<AppDatabase>(db);
  
  await DatabaseSeeder.seedCategories(db);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
