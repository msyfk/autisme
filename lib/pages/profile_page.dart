// lib/pages/profile_page.dart

import 'package:autisme/pages/edit_profile_page.dart';
import 'package:autisme/pages/login_page.dart';
import 'package:autisme/services/auth_service.dart';
import 'package:autisme/theme.dart';
import 'package:autisme/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  bool _isLoading = false;

  User? get _currentUser => _authService.currentUser;

  String get _userName =>
      _currentUser?.userMetadata?['full_name'] ?? 'Pengguna';
  String get _userEmail => _currentUser?.email ?? '-';

  String? get _userAvatarUrl =>
      _currentUser?.userMetadata?['avatar_url'] ??
      _currentUser?.userMetadata?['picture'];

  String get _userInitials {
    final name = _userName;
    if (name.isEmpty || name == 'Pengguna') return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  String get _memberSince {
    final createdAt = _currentUser?.createdAt;
    if (createdAt == null) return '-';
    final date = DateTime.parse(createdAt);
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<Map<String, dynamic>> get _children => _authService.getChildren();

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal logout: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: Column(
          children: [
            AppSurfaceCard(
              withShadow: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppTheme.detail),
                    ),
                    alignment: Alignment.center,
                    clipBehavior: Clip.hardEdge,
                    child: _userAvatarUrl != null && _userAvatarUrl!.isNotEmpty
                        ? Image.network(
                            _userAvatarUrl!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              _userInitials,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          )
                        : Text(
                            _userInitials,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.detail.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'Bergabung $_memberSince',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: AppSectionTitle(title: 'Data Anak'),
            ),
            const SizedBox(height: 12),
            AppSurfaceCard(
              padding: EdgeInsets.zero,
              child: _children.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Belum ada data anak. Silakan perbarui profil.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : Column(
                      children: _children
                          .map(
                            (child) => Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  leading: const AppIconBadge(
                                    icon: Icons.child_care_rounded,
                                    size: 44,
                                    iconSize: 22,
                                  ),
                                  title: Text(
                                    child['name'] ?? 'Nama tidak diketahui',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${_authService.getChildAgeMonths(child) ?? '-'} Bulan • ${child['gender'] == 'L'
                                        ? 'Laki-laki'
                                        : child['gender'] == 'P'
                                        ? 'Perempuan'
                                        : 'Tidak diketahui'}',
                                  ),
                                ),
                                if (child != _children.last)
                                  const Divider(indent: 76),
                              ],
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: AppSectionTitle(title: 'Pengaturan'),
            ),
            const SizedBox(height: 12),
            AppSurfaceCard(
              padding: EdgeInsets.zero,
              child: _buildMenuItem(
                icon: Icons.person_rounded,
                title: 'Ubah Profil',
                onTap: _navigateToEditProfile,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(_isLoading ? 'Keluar...' : 'Keluar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: AppIconBadge(icon: icon, size: 44, iconSize: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
