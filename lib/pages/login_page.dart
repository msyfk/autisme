// lib/pages/login_page.dart

import 'dart:async';

import 'package:autisme/pages/child_onboarding_page.dart';
import 'package:autisme/pages/main_navigation.dart';
import 'package:autisme/pages/register_page.dart';
import 'package:autisme/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges.listen((data) {
      if (data.session != null && mounted) {
        _navigateAfterAuth();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateAfterAuth() {
    final Widget nextPage = _authService.hasCompletedChildProfile
        ? const MainNavigation()
        : const ChildOnboardingPage();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validasi input
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email dan password harus diisi', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null && mounted) {
        _navigateAfterAuth();
      }
    } catch (e) {
      String errorMessage = 'Login gagal';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Email atau password salah';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Silakan verifikasi email Anda terlebih dahulu';
      }
      _showSnackBar(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(Future<bool> Function() signIn) async {
    setState(() => _isLoading = true);
    try {
      final launched = await signIn();
      if (!launched) {
        _showSnackBar('Gagal membuka halaman login sosial', isError: true);
      }
    } catch (e) {
      _showSnackBar('Login sosial gagal: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo or Graphic
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Selamat Datang',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Masuk untuk melanjutkan',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 20),

              // Password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 40),

              // Tombol Login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMiniSocialButton(
                    icon: FontAwesomeIcons.google,
                    color: const Color(0xFFDB4437), // Google Red
                    onPressed: _isLoading
                        ? null
                        : () =>
                              _handleSocialLogin(_authService.signInWithGoogle),
                  ),
                  const SizedBox(width: 20),
                  _buildMiniSocialButton(
                    icon: FontAwesomeIcons.facebook,
                    color: const Color(0xFF1877F2), // Facebook Blue
                    onPressed: _isLoading
                        ? null
                        : () => _handleSocialLogin(
                            _authService.signInWithFacebook,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Link ke Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                    child: const Text('Daftar di sini'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSocialButton({
    required dynamic icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Center(child: FaIcon(icon, size: 28, color: color)),
      ),
    );
  }
}
