// lib/pages/home_page.dart
import 'package:autisme/pages/screening_page.dart';
import 'package:autisme/theme.dart';
import 'package:autisme/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onOpenHistory;

  const HomePage({super.key, this.onOpenHistory});

  void _showAgeDialog(BuildContext context) {
    final TextEditingController ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Data Anak'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan usia anak dalam bulan.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Usia (Bulan)',
                  hintText: 'Misal: 24',
                  prefixIcon: Icon(Icons.cake_rounded),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ageController.text.isNotEmpty) {
                  int age = int.parse(ageController.text);
                  if (age < 1 || age > 72) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Usia harus antara 1 - 72 bulan'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreeningPage(childAgeMonths: age),
                    ),
                  );
                }
              },
              child: const Text('Mulai'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIconBadge(
                    icon: Icons.family_restroom_rounded,
                    size: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Ayah/Bunda',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Selamat Datang!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppSurfaceCard(
                color: AppTheme.accent,
                borderColor: AppTheme.detail,
                withShadow: true,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Screening perkembangan anak',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Deteksi Dini Autisme',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pantau perkembangan anak dengan screening rutin yang mudah dan terarah.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.textPrimary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showAgeDialog(context),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Mulai Screening'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const AppSectionTitle(
                title: 'Layanan Utama',
                subtitle: 'Akses cepat fitur yang sering digunakan',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      Icons.assignment_rounded,
                      'Screening',
                      'Mulai tes baru',
                      () => _showAgeDialog(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      Icons.history_rounded,
                      'Riwayat',
                      'Lihat hasil lama',
                      onOpenHistory ?? () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppSurfaceCard(
                child: Row(
                  children: [
                    const AppIconBadge(
                      icon: Icons.tips_and_updates_rounded,
                      size: 46,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Screening berkala membantu orang tua memahami pola perkembangan anak.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconBadge(icon: icon, size: 46),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
