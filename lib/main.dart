import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_theme.dart';
import 'core/services/recurring_service.dart';
import 'data/database/app_database.dart';
import 'data/database/seeder.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final db = AppDatabase();
  GetIt.instance.registerSingleton<AppDatabase>(db);

  await DatabaseSeeder.seedCategories(db);
  await initRecurringService();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingAsync = ref.watch(onboardingStatusProvider);

    return MaterialApp(
      title: 'Money Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: onboardingAsync.when(
        data: (isDone) => isDone ? const MainShell() : const OnboardingScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const MainShell(),
      ),
    );
  }
}
