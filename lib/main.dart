import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autisme/pages/splash_screen.dart';
import 'package:autisme/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
        'https://ykzekfcaasndivbdsxkh.supabase.co', // Ganti dengan URL project Anda
    anonKey:
        'sb_publishable_iRmpjaLH77upiAbsNrURhw_l4YKhmXb', // Ganti dengan Anon Key Anda
  );

  // Inisialisasi Notification Service
  await NotificationService().initialize();

  runApp(const MyApp());
}

// Helper untuk akses Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
