import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../firebase/firebase_helper.dart';
import 'riwayat_screen.dart';
import 'notif_screen.dart';
import 'account_settings_screen.dart';
import '../publik_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String _name = '';
  String _nim = '';
  String _role = '';
  String? _photoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final helper = FirebaseHelper();
    final user = helper.currentUser;
    if (user == null) {
      _name = 'Abdul Hakim';
      _nim = '2400016015';
      _role = 'Mahasiswa';
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await helper.getUserData(user.uid);
      if (data != null) {
        _name = data['name'] ?? user.displayName ?? 'User';
        _nim = data['nim'] ?? '';
        _role = data['role'] == 'sarpras' ? 'Staf Sarpras' : 'Mahasiswa';
        _photoUrl = data['photoUrl'];
      } else {
        _name = user.displayName ?? 'User';
      }
    } catch (e) {
      debugPrint('[ProfilScreen] Error load profile: $e');
      _name = user.displayName ?? 'Abdul Hakim';
      _nim = '2400016015';
      _role = 'Mahasiswa';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    await FirebaseHelper().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PublikScreen()),
      (_) => false,
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final avatarSize =
        (MediaQuery.of(context).size.width * 0.28).clamp(80.0, 120.0);
    const headerRatio = 0.35;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * headerRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Center(
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                          image: (_photoUrl != null && _photoUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(_photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (_photoUrl == null || _photoUrl!.isEmpty)
                            ? Center(
                                child: Text(
                                  _initials(_name),
                                  style: GoogleFonts.manrope(
                                    fontSize: avatarSize * 0.38,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    _name,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nim.isNotEmpty ? '$_nim · $_role' : _role,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Expanded(
                            child: StatCard(value: '4', label: 'Laporan')),
                        SizedBox(width: 10),
                        Expanded(
                            child:
                                StatCard(value: '4.75★', label: 'Avg Rating')),
                        SizedBox(width: 10),
                        Expanded(child: StatCard(value: '2', label: 'Selesai')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _MenuItem(
                          icon: Icons.list_alt_outlined,
                          label: 'Riwayat Laporan Saya',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RiwayatScreen())),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifikasi',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotifScreen())),
                          badge: '2',
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          label: 'Pengaturan Akun',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AccountSettingsScreen())),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _MenuItem(
                          icon: Icons.logout,
                          label: 'Keluar',
                          color: AppColors.red,
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badge;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.slate;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios,
                size: 13, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
