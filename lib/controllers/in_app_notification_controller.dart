// lib/controllers/in_app_notification_controller.dart

import 'dart:convert';
import 'package:autisme/models/in_app_notification_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppNotificationController extends GetxController {
  static const String _storageKey = 'in_app_notifications';

  final notifications = <InAppNotification>[].obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
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

    // Buat dummy notifikasi selamat datang jika kosong untuk keperluan pengujian
    if (notifications.isEmpty) {
      addNotification(
        title: 'Selamat Datang! 🎉',
        body: 'Terima kasih telah menggunakan aplikasi NeuroSense.',
      );
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
