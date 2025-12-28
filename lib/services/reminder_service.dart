// lib/services/reminder_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autisme/models/reminder_model.dart';
import 'package:autisme/services/notification_service.dart';

class ReminderService {
  static const String _reminderKey = 'reminder_settings';

  final NotificationService _notificationService = NotificationService();

  // Ambil pengaturan pengingat dari SharedPreferences
  Future<ReminderSettings> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_reminderKey);

    if (jsonString != null) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return ReminderSettings.fromMap(map);
    }

    return ReminderSettings(); // Default settings
  }

  // Simpan pengaturan pengingat ke SharedPreferences
  Future<void> saveReminderSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(settings.toMap());
    await prefs.setString(_reminderKey, jsonString);

    // Update jadwal notifikasi berdasarkan pengaturan baru
    if (settings.isEnabled) {
      await _notificationService.scheduleWeeklyReminder(
        dayOfWeek: settings.dayOfWeek,
        timeOfDay: settings.timeOfDay,
      );
    } else {
      await _notificationService.cancelReminder();
    }
  }

  // Update tanggal screening terakhir
  Future<void> updateLastScreeningDate() async {
    final settings = await getReminderSettings();
    final now = DateTime.now();

    final updatedSettings = settings.copyWith(
      lastScreeningDate: now,
      nextReminderDate: settings.calculateNextReminderDate(),
    );

    await saveReminderSettings(updatedSettings);
  }

  // Toggle pengingat on/off
  Future<ReminderSettings> toggleReminder(bool isEnabled) async {
    final settings = await getReminderSettings();

    final updatedSettings = settings.copyWith(
      isEnabled: isEnabled,
      nextReminderDate: isEnabled ? settings.calculateNextReminderDate() : null,
    );

    await saveReminderSettings(updatedSettings);
    return updatedSettings;
  }

  // Update hari pengingat
  Future<ReminderSettings> updateReminderDay(int dayOfWeek) async {
    final settings = await getReminderSettings();

    final updatedSettings = settings.copyWith(
      dayOfWeek: dayOfWeek,
      nextReminderDate: settings.isEnabled
          ? ReminderSettings(
              dayOfWeek: dayOfWeek,
              timeOfDay: settings.timeOfDay,
            ).calculateNextReminderDate()
          : null,
    );

    await saveReminderSettings(updatedSettings);
    return updatedSettings;
  }

  // Update waktu pengingat
  Future<ReminderSettings> updateReminderTime(TimeOfDay timeOfDay) async {
    final settings = await getReminderSettings();

    final updatedSettings = settings.copyWith(
      timeOfDay: timeOfDay,
      nextReminderDate: settings.isEnabled
          ? ReminderSettings(
              dayOfWeek: settings.dayOfWeek,
              timeOfDay: timeOfDay,
            ).calculateNextReminderDate()
          : null,
    );

    await saveReminderSettings(updatedSettings);
    return updatedSettings;
  }

  // Hitung selisih hari sampai pengingat berikutnya
  int getDaysUntilNextReminder(ReminderSettings settings) {
    if (!settings.isEnabled || settings.nextReminderDate == null) {
      return -1;
    }

    final now = DateTime.now();
    final difference = settings.nextReminderDate!.difference(now);
    return difference.inDays;
  }

  // Format tanggal untuk ditampilkan
  String formatDate(DateTime? date) {
    if (date == null) return '-';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
