import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_provider.dart';
import 'transaction_providers.dart';
import 'budget_providers.dart';

// --- Theme Provider ---

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _themeKey = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString == 'dark') {
      state = ThemeMode.dark;
    } else if (themeString == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }
}

// --- App Version Provider ---

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

// --- Reset Data Provider ---

final resetDataProvider = Provider((ref) {
  return () async {
    final db = ref.read(databaseProvider);
    await db.resetAllData();
    
    // Invalidate caches to refresh UIs
    ref.invalidate(transactionsStreamProvider);
    ref.invalidate(transactionsByDateRangeProvider);
    ref.invalidate(monthlyTotalProvider);
    ref.invalidate(budgetsProvider);
  };
});
