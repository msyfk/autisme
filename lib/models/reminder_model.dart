// lib/models/reminder_model.dart

import 'package:flutter/material.dart';

class ReminderSettings {
  final bool isEnabled;
  final int dayOfWeek; // 1 = Senin, 7 = Minggu
  final TimeOfDay timeOfDay;
  final DateTime? lastScreeningDate;
  final DateTime? nextReminderDate;

  ReminderSettings({
    this.isEnabled = false,
    this.dayOfWeek = 1, // Default: Senin
    this.timeOfDay = const TimeOfDay(hour: 9, minute: 0), // Default: 09:00
    this.lastScreeningDate,
    this.nextReminderDate,
  });

  // Convert dari Map (untuk SharedPreferences)
  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      isEnabled: map['isEnabled'] ?? false,
      dayOfWeek: map['dayOfWeek'] ?? 1,
      timeOfDay: TimeOfDay(hour: map['hour'] ?? 9, minute: map['minute'] ?? 0),
      lastScreeningDate: map['lastScreeningDate'] != null
          ? DateTime.tryParse(map['lastScreeningDate'])
          : null,
      nextReminderDate: map['nextReminderDate'] != null
          ? DateTime.tryParse(map['nextReminderDate'])
          : null,
    );
  }

  // Convert ke Map (untuk SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'dayOfWeek': dayOfWeek,
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
      'lastScreeningDate': lastScreeningDate?.toIso8601String(),
      'nextReminderDate': nextReminderDate?.toIso8601String(),
    };
  }

  // Copy with method untuk update parsial
  ReminderSettings copyWith({
    bool? isEnabled,
    int? dayOfWeek,
    TimeOfDay? timeOfDay,
    DateTime? lastScreeningDate,
    DateTime? nextReminderDate,
  }) {
    return ReminderSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      lastScreeningDate: lastScreeningDate ?? this.lastScreeningDate,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
    );
  }

  // Mendapatkan nama hari dalam Bahasa Indonesia
  String get dayName {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[dayOfWeek - 1];
  }

  // Format waktu menjadi string
  String get timeString {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Hitung tanggal pengingat berikutnya
  DateTime calculateNextReminderDate() {
    final now = DateTime.now();

    // Cari tanggal berikutnya dengan hari yang sesuai
    int daysUntilNext = dayOfWeek - now.weekday;
    if (daysUntilNext <= 0) {
      daysUntilNext += 7; // Minggu depan
    }

    // Jika hari ini adalah hari yang dipilih, cek apakah waktu sudah lewat
    if (daysUntilNext == 7 && now.weekday == dayOfWeek) {
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      if (now.isBefore(scheduledTime)) {
        daysUntilNext = 0; // Hari ini
      }
    }

    final nextDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilNext,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    return nextDate;
  }
}
