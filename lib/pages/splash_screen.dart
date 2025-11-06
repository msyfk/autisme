// lib/pages/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autisme/pages/home_page.dart'; // Pastikan impor ini benar

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Menjalankan navigasi setelah 3 detik
    Timer(
      const Duration(seconds: 3),
      () => Navigator.pushReplacement(
        context,
        // Mengarahkan ke HomePage (Dashboard)
        MaterialPageRoute(builder: (context) => const HomePage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 8),

            // 2. Nama Aplikasi
            Text(
              'NeuroSense', // Nama dari pubspec.yaml
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),

            // Indikator loading dan SizedBox di bawahnya telah dihapus.
          ],
        ),
      ),
    );
  }
}
