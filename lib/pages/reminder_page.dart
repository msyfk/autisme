// lib/pages/reminder_page.dart

import 'package:flutter/material.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Hapus AppBar dari sini
    return Scaffold(
      body: Center(
        child: Text('Halaman Pengingat', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
