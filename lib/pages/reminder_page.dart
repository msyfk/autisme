// lib/pages/reminder_page.dart

import 'package:autisme/theme.dart';
import 'package:autisme/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:autisme/models/reminder_model.dart';
import 'package:autisme/services/reminder_service.dart';
import 'package:autisme/services/notification_service.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderService _reminderService = ReminderService();
  final NotificationService _notificationService = NotificationService();

  ReminderSettings? _settings;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _days = [
    {'value': 1, 'name': 'Senin'},
    {'value': 2, 'name': 'Selasa'},
    {'value': 3, 'name': 'Rabu'},
    {'value': 4, 'name': 'Kamis'},
    {'value': 5, 'name': 'Jumat'},
    {'value': 6, 'name': 'Sabtu'},
    {'value': 7, 'name': 'Minggu'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _reminderService.getReminderSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin notifikasi diperlukan untuk pengingat'),
            ),
          );
        }
        return;
      }
    }

    final updatedSettings = await _reminderService.toggleReminder(value);
    setState(() => _settings = updatedSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Pengingat diaktifkan' : 'Pengingat dinonaktifkan',
          ),
        ),
      );
    }
  }

  Future<void> _updateDay(int dayOfWeek) async {
    final updatedSettings = await _reminderService.updateReminderDay(dayOfWeek);
    setState(() => _settings = updatedSettings);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _settings?.timeOfDay ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      final updatedSettings = await _reminderService.updateReminderTime(picked);
      setState(() => _settings = updatedSettings);
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notifikasi test dikirim!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Pengingat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSurfaceCard(
              color: AppTheme.accent.withValues(alpha: 0.65),
              borderColor: AppTheme.detail.withValues(alpha: 0.32),
              withShadow: true,
              child: Row(
                children: [
                  const AppIconBadge(
                    icon: Icons.notifications_active_rounded,
                    size: 56,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Rutin',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dapatkan pengingat untuk screening berkala.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const AppSectionTitle(title: 'Pengaturan Jadwal'),
            const SizedBox(height: 12),
            AppSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    title: const Text(
                      'Aktifkan Notifikasi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _settings!.isEnabled ? 'Sedang aktif' : 'Dinonaktifkan',
                    ),
                    value: _settings!.isEnabled,
                    onChanged: _toggleReminder,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    leading: const AppIconBadge(
                      icon: Icons.calendar_month_rounded,
                      size: 42,
                      iconSize: 22,
                    ),
                    title: const Text(
                      'Hari',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: DropdownButton<int>(
                      value: _settings!.dayOfWeek,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.expand_more_rounded),
                      style: Theme.of(context).textTheme.bodyLarge,
                      items: _days
                          .map(
                            (day) => DropdownMenuItem<int>(
                              value: day['value'] as int,
                              child: Text(day['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: _settings!.isEnabled
                          ? (value) => value != null ? _updateDay(value) : null
                          : null,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    leading: const AppIconBadge(
                      icon: Icons.access_time_rounded,
                      size: 42,
                      iconSize: 22,
                    ),
                    title: const Text(
                      'Waktu',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: TextButton.icon(
                      onPressed: _settings!.isEnabled ? _selectTime : null,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(_settings!.timeString),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_settings!.isEnabled) ...[
              const AppSectionTitle(title: 'Status Berikutnya'),
              const SizedBox(height: 12),
              AppSurfaceCard(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderColor: AppTheme.success.withValues(alpha: 0.25),
                child: Row(
                  children: [
                    const AppIconBadge(
                      icon: Icons.event_available_rounded,
                      color: AppTheme.success,
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${_settings!.dayName}, ${_reminderService.formatDate(_settings!.calculateNextReminderDate())}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            OutlinedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Test Notifikasi'),
            ),
          ],
        ),
      ),
    );
  }
}
