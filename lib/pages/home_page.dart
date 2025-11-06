// lib/pages/home_page.dart

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Hapus AppBar dari sini
    return Scaffold(
      // 2. Body sekarang menjadi isi utama
      body: const Center(
        child: Text(
          'Selamat Datang di Halaman Utama!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
