// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Callback saat notifikasi di-tap
  static Function(String?)? onNotificationTap;

  // Inisialisasi service
  Future<void> initialize() async {
    // Inisialisasi timezone
    tz.initializeTimeZones();

    // Konfigurasi Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Konfigurasi iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle tap pada notifikasi
        if (onNotificationTap != null) {
          onNotificationTap!(response.payload);
        }
      },
    );
  }

  // Minta izin notifikasi (khusus Android 13+)
  Future<bool> requestPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // Jadwalkan notifikasi mingguan
  Future<void> scheduleWeeklyReminder({
    required int dayOfWeek, // 1 = Senin, 7 = Minggu
    required TimeOfDay timeOfDay,
  }) async {
    // Batalkan notifikasi sebelumnya
    await cancelReminder();

    // Konversi dayOfWeek ke format DateTime (1 = Senin)
    // DateTime.weekday: 1 = Senin, 7 = Minggu

    final now = tz.TZDateTime.now(tz.local);

    // Hitung tanggal berikutnya dengan hari yang sesuai
    int daysUntilNext = dayOfWeek - now.weekday;
    if (daysUntilNext <= 0) {
      daysUntilNext += 7;
    }

    // Jika hari ini dan waktu belum lewat
    if (daysUntilNext == 7 && now.weekday == dayOfWeek) {
      final scheduledToday = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      if (now.isBefore(scheduledToday)) {
        daysUntilNext = 0;
      }
    }

    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilNext,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    const androidDetails = AndroidNotificationDetails(
      'weekly_screening_reminder',
      'Pengingat Screening Mingguan',
      channelDescription:
          'Notifikasi pengingat untuk melakukan screening autisme mingguan',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      0, // ID notifikasi
      'Waktunya Screening! 📋',
      'Sudah seminggu sejak screening terakhir. Yuk, lakukan screening untuk memantau perkembangan anak Anda.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'screening_reminder',
    );

    debugPrint('Notifikasi dijadwalkan untuk: $scheduledDate');
  }

  // Batalkan semua pengingat
  Future<void> cancelReminder() async {
    await _notifications.cancel(0);
  }

  // Tampilkan notifikasi langsung (untuk testing)
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_notification',
      'Test Notifikasi',
      channelDescription: 'Channel untuk testing notifikasi',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Test Pengingat Screening 📋',
      'Ini adalah notifikasi test. Jika Anda melihat ini, pengingat berfungsi dengan baik!',
      details,
      payload: 'test_notification',
    );
  }
}
