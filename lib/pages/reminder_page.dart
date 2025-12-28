// lib/pages/reminder_page.dart

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
      // Minta izin notifikasi terlebih dahulu
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin notifikasi diperlukan untuk pengingat'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final updatedSettings = await _reminderService.toggleReminder(value);
    setState(() {
      _settings = updatedSettings;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Pengingat diaktifkan' : 'Pengingat dinonaktifkan',
          ),
          backgroundColor: value ? Colors.green : Colors.grey,
        ),
      );
    }
  }

  Future<void> _updateDay(int dayOfWeek) async {
    final updatedSettings = await _reminderService.updateReminderDay(dayOfWeek);
    setState(() {
      _settings = updatedSettings;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _settings?.timeOfDay ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade800),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final updatedSettings = await _reminderService.updateReminderTime(picked);
      setState(() {
        _settings = updatedSettings;
      });
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi test dikirim!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Pengaturan Pengingat Card
            _buildSettingsCard(),
            const SizedBox(height: 16),

            // Status Card
            if (_settings!.isEnabled) _buildStatusCard(),
            const SizedBox(height: 16),

            // Test Button
            _buildTestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.notifications_active,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Pengingat Screening',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dapatkan pengingat mingguan untuk melakukan screening dan memantau perkembangan anak Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const Divider(),

            // Toggle Pengingat
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Aktifkan Pengingat',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _settings!.isEnabled
                    ? 'Pengingat aktif - Anda akan diingatkan setiap minggu'
                    : 'Pengingat tidak aktif',
              ),
              value: _settings!.isEnabled,
              activeThumbColor: Colors.blue.shade800,
              onChanged: _toggleReminder,
            ),
            const Divider(),

            // Pilih Hari
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Hari Pengingat',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: DropdownButton<int>(
                value: _settings!.dayOfWeek,
                underline: const SizedBox(),
                items: _days.map((day) {
                  return DropdownMenuItem<int>(
                    value: day['value'] as int,
                    child: Text(day['name'] as String),
                  );
                }).toList(),
                onChanged: _settings!.isEnabled
                    ? (value) {
                        if (value != null) _updateDay(value);
                      }
                    : null,
              ),
            ),
            const Divider(),

            // Pilih Waktu
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Waktu Pengingat',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: TextButton.icon(
                onPressed: _settings!.isEnabled ? _selectTime : null,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _settings!.timeString,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final nextDate = _settings!.calculateNextReminderDate();
    final daysUntil = nextDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.green.shade50,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Status Pengingat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Jadwal Berikutnya
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Pengingat Berikutnya',
              value:
                  '${_settings!.dayName}, ${_reminderService.formatDate(nextDate)}',
            ),
            const SizedBox(height: 8),

            // Waktu
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Waktu',
              value: _settings!.timeString,
            ),
            const SizedBox(height: 8),

            // Countdown
            _buildInfoRow(
              icon: Icons.hourglass_empty,
              label: 'Waktu Tersisa',
              value: daysUntil == 0
                  ? 'Hari ini!'
                  : daysUntil == 1
                  ? 'Besok'
                  : '$daysUntil hari lagi',
            ),

            // Screening Terakhir
            if (_settings!.lastScreeningDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.history,
                label: 'Screening Terakhir',
                value: _reminderService.formatDate(
                  _settings!.lastScreeningDate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTestButton() {
    return OutlinedButton.icon(
      onPressed: _testNotification,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.blue.shade800),
      ),
      icon: const Icon(Icons.send),
      label: const Text('Kirim Notifikasi Test'),
    );
  }
}
