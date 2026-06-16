// lib/pages/splash_screen.dart

import 'dart:async';
import 'package:autisme/theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autisme/pages/child_onboarding_page.dart';
import 'package:autisme/pages/login_page.dart';
import 'package:autisme/pages/main_navigation.dart';
import 'package:autisme/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    final authService = AuthService();
    final Widget nextPage = session == null
        ? const LoginPage()
        : authService.hasCompletedChildProfile
        ? const MainNavigation()
        : const ChildOnboardingPage();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _decorCircle(210, AppTheme.accent.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: -90,
            left: -80,
            child: _decorCircle(230, AppTheme.detail.withValues(alpha: 0.18)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: AppTheme.detail.withValues(alpha: 0.24),
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 132,
                      height: 132,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'NeuroSense',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Peduli, hangat, dan deteksi dini',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 44),
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
