// lib/pages/notification_page.dart

import 'package:autisme/controllers/in_app_notification_controller.dart';
import 'package:autisme/theme.dart';
import 'package:autisme/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _notifController = Get.find<InAppNotificationController>();

  @override
  void initState() {
    super.initState();
    // Tandai semua dibaca ketika halaman ini ditutup
    timeago.setLocaleMessages('id', timeago.IdMessages());
  }

  @override
  void dispose() {
    _notifController.markAllAsRead();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: 'Bersihkan semua',
            onPressed: () {
              _notifController.clearAll();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_notifController.notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Belum ada notifikasi',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _notifController.notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notif = _notifController.notifications[index];
            return AppSurfaceCard(
              padding: const EdgeInsets.all(16),
              withShadow: !notif.isRead, // shadow tipis jika belum dibaca
              borderColor: notif.isRead
                  ? Colors.grey.shade200
                  : AppTheme.detail,
              color: notif.isRead
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? Colors.grey.shade100
                          : AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: notif.isRead
                          ? Colors.grey.shade400
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: notif.isRead
                                          ? FontWeight.normal
                                          : FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif.body,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: notif.isRead
                                    ? Colors.grey.shade600
                                    : AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeago.format(notif.timestamp, locale: 'id'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
