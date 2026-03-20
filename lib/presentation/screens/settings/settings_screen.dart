import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/export_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_providers.dart';
import '../recurring/recurring_screen.dart';
import 'category_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _exportCurrentMonth(bool isPdf) async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      final allTxs = await ref.read(transactionsStreamProvider.future);
      final txs = allTxs.where((t) {
        return t.date.isAfter(firstDay.subtract(const Duration(seconds: 1))) &&
               t.date.isBefore(lastDay.add(const Duration(seconds: 1)));
      }).toList();
      if (txs.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data bulan ini')));
        return;
      }
      
      if (isPdf) {
        await ExportService.exportToPDF(txs, now.month, now.year);
      } else {
        await ExportService.exportToCSV(txs);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ekspor gagal: $e')));
    }
  }

  void _exportCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime(DateTime.now().year, DateTime.now().month, 1),
        end: DateTime.now(),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppTheme.primaryGreen,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (range != null && mounted) {
      final endDay = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      try {
        final allTxs = await ref.read(transactionsStreamProvider.future);
        final txs = allTxs.where((t) {
          return t.date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
                 t.date.isBefore(endDay.add(const Duration(seconds: 1)));
        }).toList();
        if (txs.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data di rentang waktu ini')));
          return;
        }
        await ExportService.exportToCSV(txs);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ekspor gagal: $e')));
      }
    }
  }

  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Semua Data'),
        content: const Text(
          'Tindakan ini akan menghapus permanen SEMUA histori transaksi, anggaran, dan data berulang. '
          'Kategori yang Anda miliki tidak akan dihapus.\n\nAnda yakin ingin melanjutkan?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(resetDataProvider)();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua data telah direset')));
              }
            },
            child: const Text('Ya, Hapus Semua Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final versionAsync = ref.watch(appVersionProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // FITUR
          _buildSectionHeader('Fitur'),
          ListTile(
            leading: const Icon(Icons.repeat_rounded, color: AppTheme.primaryGreen),
            title: const Text('Transaksi Berulang'),
            subtitle: const Text('Kelola transaksi yang otomatis dicatat'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()));
            },
          ),
          const Divider(),

          // DATA MANAGEMENT
          _buildSectionHeader('Manajemen Data'),
          ListTile(
            leading: const Icon(Icons.table_chart, color: AppTheme.accentGreen),
            title: const Text('Ekspor Bulan Ini (CSV)'),
            subtitle: const Text('Format spreadsheet file'),
            onTap: () => _exportCurrentMonth(false),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            title: const Text('Ekspor Laporan Bulan Ini (PDF)'),
            subtitle: const Text('Format laporan lengkap'),
            onTap: () => _exportCurrentMonth(true),
          ),
          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.blueAccent),
            title: const Text('Ekspor Rentang Waktu (CSV)'),
            subtitle: const Text('Pilih tanggal awal dan akhir'),
            onTap: _exportCustomRange,
          ),
          const Divider(),

          // CATEGORY
          _buildSectionHeader('Kategori'),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.orange),
            title: const Text('Kelola Kategori Custom'),
            subtitle: const Text('Tambah, edit, atau hapus kategori'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
            },
          ),
          const Divider(),

          // APP
          _buildSectionHeader('Aplikasi'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Colors.indigo),
            title: const Text('Mode Gelap'),
            value: isDark,
            activeThumbColor: AppTheme.accentGreen,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text('Versi Aplikasi'),
            trailing: versionAsync.when(
              data: (v) => Text(v, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, _) => const Text('Error'),
            ),
          ),
          const SizedBox(height: 32),

          // DANGER ZONE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset Semua Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _confirmResetData,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentGreen, letterSpacing: 1.2),
      ),
    );
  }
}
