import 'dart:async';
import 'package:flutter/material.dart';

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
        MaterialPageRoute(builder: (context) => const SplashScreen()),
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
            // 1. Logo Aplikasi
            // Kita gunakan FlutterLogo sebagai placeholder.
            // Ganti dengan Image.asset('assets/logo.png') jika Anda punya logo sendiri.
            const FlutterLogo(size: 120),

            const SizedBox(height: 24),

            // 2. Nama Aplikasi
            Text(
              'autisme', // Nama dari pubspec.yaml
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800, // Warna yang kuat dan modern
              ),
            ),

            const SizedBox(height: 32),

            // 3. Indikator Loading
            CircularProgressIndicator(
              // Memberi warna pada indikator loading
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
            ),
          ],
        ),
      ),
    );
  }
}
