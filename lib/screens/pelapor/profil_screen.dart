import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // TAMBAHAN
import '../../theme/app_theme.dart';
import '../../firebase/firebase_helper.dart';
import '../../providers/notification_provider.dart'; // TAMBAHAN
import 'riwayat_screen.dart';
import 'notif_screen.dart';
import 'account_settings_screen.dart';
import '../publik_screen.dart';
import '../../models/models.dart';
import '../../providers/report_provider.dart';
import '../sarpras/sarpras_riwayat_screen.dart';

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
    const headerRatio = 0.28;
    // TAMBAHAN: ambil angka unread yang sama persis dengan yang dipakai Home Screen
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final reportProvider = context.watch<ReportProvider>();

final reports = reportProvider.reports;

final totalLaporan = reports.length;
final reportsDenganRating = reports.where((r) =>
    r.status == ReportStatus.selesai &&
    r.rating != null).toList();

final ratingCount = reportsDenganRating.length;

final averageRating = ratingCount == 0
    ? 0.0
    : reportsDenganRating
            .map((r) => r.rating!)
            .reduce((a, b) => a + b) /
        ratingCount;

/// total laporan yang benar-benar selesai
final totalSelesai = reports.where(
  (r) => r.status == ReportStatus.selesai,
).length;

/// total laporan yang sedang/sudah ditangani (khusus statistik Sarpras)
final totalHandled = reports.where(
  (r) =>
      r.status == ReportStatus.diproses ||
      r.status == ReportStatus.selesai,
).length;

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
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                '$totalLaporan',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Laporan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 1,
          height: 40,
          color: Colors.white24,
        ),

        Expanded(
          child: Column(
            children: [
             Text(
  '$totalSelesai',
  style: GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  ),
),
              const SizedBox(height: 4),
              Text(
                'Selesai',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
                  const SizedBox(height: 20),
                  if (_role == 'Staf Sarpras') ...[
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [

          Row(
            children: [
              const Icon(Icons.star,
                  color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rating Kinerja",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "$ratingCount Penilaian",
                      style: GoogleFonts.inter(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                averageRating.toStringAsFixed(1),
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
Center(
  child: Column(
    children: [
      Text(
        "$totalHandled",
        style: GoogleFonts.manrope(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        "Laporan Ditangani",
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),
        ],
      ),
    ),
  ),

  const SizedBox(height: 20),
],
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
  label: _role == 'Staf Sarpras'
      ? 'Riwayat Laporan'
      : 'Riwayat Laporan Saya',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _role == 'Staf Sarpras'
          ? const SarprasRiwayatScreen()
          : const RiwayatScreen(),
    ),
  ),
),
                        const Divider(height: 1, color: AppColors.line),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifikasi',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotifScreen())),
                          // GANTI: dari badge: '2' (hardcode) menjadi angka asli, null kalau 0
                          badge: unreadCount > 0 ? '$unreadCount' : null,
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