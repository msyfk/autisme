import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Selamat Datang di Halaman Utama!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
