import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyReminderService {
  static const int _notificationId = 2001;
  static const String enabledKey = 'daily_reminder_enabled';
  static const String hourKey = 'daily_reminder_hour';
  static const String minuteKey = 'daily_reminder_minute';

  final FlutterLocalNotificationsPlugin _notifications;

  DailyReminderService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await cancelDailyReminder();
    await _initializeNotifications();
    await _configureLocalTimezone();

    await _notifications.zonedSchedule(
      id: _notificationId,
      title: 'Pengingat Transaksi',
      body: 'Hari ini ada pengeluaran yang belum dicatat? 📝',
      scheduledDate: _nextInstanceOfTime(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Pengingat Harian',
          channelDescription: 'Pengingat harian untuk mencatat transaksi',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() {
    return _notifications.cancel(id: _notificationId);
  }

  Future<void> scheduleFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(enabledKey) ?? true;
    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    final hour = prefs.getInt(hourKey) ?? 20;
    final minute = prefs.getInt(minuteKey) ?? 0;
    await scheduleDailyReminder(TimeOfDay(hour: hour, minute: minute));
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _notifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _configureLocalTimezone() async {
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
