import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/daily_reminder_service.dart';

class DailyReminderSetting extends StatefulWidget {
  const DailyReminderSetting({super.key});

  @override
  State<DailyReminderSetting> createState() => _DailyReminderSettingState();
}

class _DailyReminderSettingState extends State<DailyReminderSetting> {
  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(DailyReminderService.enabledKey) ?? true;
      _time = TimeOfDay(
        hour: prefs.getInt(DailyReminderService.hourKey) ?? 20,
        minute: prefs.getInt(DailyReminderService.minuteKey) ?? 0,
      );
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DailyReminderService.enabledKey, value);

    if (value) {
      await DailyReminderService().scheduleDailyReminder(_time);
    } else {
      await DailyReminderService().cancelDailyReminder();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;

    setState(() => _time = picked);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(DailyReminderService.hourKey, picked.hour);
    await prefs.setInt(DailyReminderService.minuteKey, picked.minute);

    if (_enabled) {
      await DailyReminderService().scheduleDailyReminder(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(
            Icons.notifications_active_rounded,
            color: AppTheme.accentGreen,
          ),
          title: const Text('Pengingat Catat Transaksi'),
          subtitle: Text(
            _enabled
                ? 'Setiap hari pukul ${_time.format(context)}'
                : 'Tidak aktif',
          ),
          value: _enabled,
          activeThumbColor: AppTheme.accentGreen,
          onChanged: _setEnabled,
        ),
        if (_enabled)
          ListTile(
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Jam Pengingat'),
            trailing: Text(
              _time.format(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: _pickTime,
          ),
      ],
    );
  }
}
