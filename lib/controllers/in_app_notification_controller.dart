// lib/controllers/in_app_notification_controller.dart

import 'dart:convert';
import 'package:autisme/models/in_app_notification_model.dart';
import 'package:autisme/services/reminder_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InAppNotificationController extends GetxController {
  static const String _baseStorageKey = 'in_app_notifications';

  String get _storageKey {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId == null ? _baseStorageKey : '${_baseStorageKey}_$userId';
  }

  final notifications = <InAppNotification>[].obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  void markAsReadAndSave() {
    markAllAsRead();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      notifications.value =
          jsonList.map((map) => InAppNotification.fromMap(map)).toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    // Sinkronisasi dengan jadwal pengingat OS
    try {
      final reminderService = ReminderService();
      final settings = await reminderService.getReminderSettings();

      if (settings.isEnabled && settings.nextReminderDate != null) {
        if (DateTime.now().isAfter(settings.nextReminderDate!)) {
          // Pengingat terpicu! Tambahkan ke kotak masuk
          addNotification(
            title: 'Waktunya Screening! 📋',
            body:
                'Sudah seminggu sejak screening terakhir. Yuk, pantau perkembangan anak Anda.',
          );

          // Perbarui tanggal agar tidak terus ditambah.
          // Gunakan service agar tersimpan pada key akun yang sedang login.
          final updatedSettings = settings.copyWith(
            nextReminderDate: settings.calculateNextReminderDate(),
          );
          await reminderService.saveReminderSettings(updatedSettings);
        }
      }
    } catch (e) {
      // Abaikan jika terjadi error saat sinkronisasi
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => n.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  void addNotification({required String title, required String body}) {
    final newNotif = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    notifications.insert(0, newNotif); // Masukkan paling atas
    _saveNotifications();
  }

  void markAllAsRead() {
    bool hasChanges = false;
    for (var n in notifications) {
      if (!n.isRead) {
        n.isRead = true;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifications.refresh();
      _saveNotifications();
    }
  }

  void clearAll() {
    notifications.clear();
    _saveNotifications();
  }
}
