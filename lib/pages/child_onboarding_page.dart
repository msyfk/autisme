// lib/pages/child_onboarding_page.dart

import 'package:autisme/pages/main_navigation.dart';
import 'package:autisme/services/auth_service.dart';
import 'package:autisme/theme.dart';
import 'package:autisme/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChildOnboardingPage extends StatefulWidget {
  const ChildOnboardingPage({super.key});

  @override
  State<ChildOnboardingPage> createState() => _ChildOnboardingPageState();
}

class _ChildOnboardingPageState extends State<ChildOnboardingPage> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveChildProfile() async {
    final name = _nameController.text.trim();
    final ageMonths = int.tryParse(_ageController.text.trim());

    if (name.isEmpty) {
      _showSnackBar('Nama anak harus diisi', isError: true);
      return;
    }

    if (ageMonths == null || ageMonths < 1 || ageMonths > 72) {
      _showSnackBar('Usia anak harus antara 1 - 72 bulan', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.savePrimaryChild(
        name: name,
        ageMonths: ageMonths,
        gender: _gender,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      _showSnackBar(
        'Gagal menyimpan data anak: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AppIconBadge(
                    icon: Icons.child_care_rounded,
                    size: 76,
                    iconSize: 36,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lengkapi Data Anak',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Data ini digunakan agar screening langsung memakai usia anak yang sesuai.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                AppSurfaceCard(
                  withShadow: true,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Nama Anak',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _ageController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Usia Anak (bulan)',
                          hintText: 'Contoh: 24',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kelamin (opsional)',
                          prefixIcon: Icon(Icons.wc_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'L',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'P',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) => setState(() => _gender = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveChildProfile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _isLoading ? 'Menyimpan...' : 'Simpan dan Lanjutkan',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
