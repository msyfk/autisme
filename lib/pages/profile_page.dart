// lib/pages/profile_page.dart

import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Hapus AppBar dari sini
    return Scaffold(
      body: Center(
        child: Text('Halaman Profil', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
