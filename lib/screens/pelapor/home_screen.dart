import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../firebase/firebase_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/notification_provider.dart'; // TAMBAHAN
import 'lapor_screen.dart';
import 'detail_screen.dart';
import 'riwayat_screen.dart';
import 'notif_screen.dart';
import 'profil_screen.dart' as profil;
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const RiwayatScreen(),
    const NotifScreen(),
    const profil.ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: _FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == -1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporScreen()));
          } else {
            setState(() => _currentIndex = i);
          }
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// BOTTOM NAV — pill teal mengambang + tombol "+" menonjol di atasnya,
// persis referensi. Logic tap-nya sama seperti sebelumnya (setState(_currentIndex)).
// ----------------------------------------------------------------------
class _FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _FloatingBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Jarak bawah = safe-area device + margin tambahan, biar gak tabrakan
    // dengan tombol navigasi asli HP.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 18),
      child: SizedBox(
        height: 84,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Bar pill teal
            Positioned(
              top: 26,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavIcon(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      isActive: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavIcon(
                      icon: Icons.description_outlined,
                      activeIcon: Icons.description,
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    _NavIcon(
                      icon: Icons.notifications_outlined,
                      activeIcon: Icons.notifications,
                      isActive: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                    _NavIcon(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ],
                ),
              ),
            ),
            // Tombol "+" menonjol di atas bar — tetap membuka LaporScreen (index 1)
            GestureDetector(
              // -1 is a sentinel: parent will push LaporScreen via Navigator
              onTap: () => onTap(-1),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: AppColors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive
              ? AppColors.white
              : AppColors.white.withOpacity( 0.6),
          size: 26,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// HOME CONTENT — logic (load user, provider reports, navigasi) tidak diubah,
// hanya tampilannya yang disamakan dengan mockup + badge notifikasi.
// ----------------------------------------------------------------------
class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _userName = '';
  String _initials = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseHelper().currentUser;
    if (user == null) return;
    final data = await FirebaseHelper().getUserData(user.uid);
    if (!mounted) return;
    final name = (data?['name'] as String?) ?? user.displayName ?? 'User';
    setState(() {
      _userName = name;
      _initials = _buildInitials(name);
      _loaded = true;
    });
  }

  String _buildInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final notifProvider = context.watch<NotificationProvider>(); // TAMBAHAN
    final recentReports = provider.reports.take(3).toList();

    // Dihitung otomatis dari data yang ada — kalau belum ada laporan, hasilnya 0.
    final totalLaporan = provider.reports.length;
    final sedangDiproses =
        provider.reports.where((r) => r.status == ReportStatus.diproses).length;

    final displayName = _loaded ? _userName : '...';
    final displayInitials = _loaded ? _initials : '..';

    return Column(
      children: [
        // ---- Header gradasi (tetap ada avatar inisial user, logic sama) ----
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.headerEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fix',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              'Up',
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withOpacity( 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            displayName,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity( 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        displayInitials,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ---- Kartu mengambang: stats + quick actions ----
                Transform.translate(
                  offset: const Offset(0, -70),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity( 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Laporan / Sedang diproses — dari data asli
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatColumn(
                                    value: '$totalLaporan',
                                    label: 'Total Laporan',
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 36,
                                    color: Colors.white24),
                                Expanded(
                                  child: _StatColumn(
                                    value: '$sedangDiproses',
                                    label: 'Sedang diproses',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'AKSES CEPAT',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.muted,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _QuickItem(
                                icon: Icons.qr_code_2_rounded,
                                bgColor: const Color(0xFF3B82F6),
                                label: 'Scan QR\nLokasi',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                                  );
                                },
                              ),
                              _QuickItem(
                                icon: Icons.add_alert_rounded,
                                bgColor: const Color(0xFFF97316),
                                label: 'Lapor\nKerusakan',
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LaporScreen()));
                                },
                              ),
                              _QuickItem(
                                icon: Icons.receipt_long_rounded,
                                bgColor: const Color(0xFF4F46E5),
                                label: 'Riwayat\nLaporan',
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RiwayatScreen()));
                                },
                              ),
                              _QuickItem(
                                icon: Icons.notifications_rounded,
                                bgColor: const Color(0xFF14B8A6),
                                label: 'Notifikasi',
                                // GANTI: dari showDot: true menjadi angka asli unreadCount
                                badgeCount: notifProvider.unreadCount,
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const NotifScreen()));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---- Laporan terbaru: tetap dari provider.reports ----
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionLabel('Laporan Terbaru'),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RiwayatScreen())),
                              child: Text(
                                'Lihat semua →',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (recentReports.isEmpty)
                          const _EmptyReportsPlaceholder()
                        else
                          ...recentReports.map((r) => ReportCard(
                                report: r,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DetailScreen(report: r)),
                                ),
                              )),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Tile kotak warna solid + ikon putih, sama persis seperti referensi gambar.
// GANTI: showDot (boolean) menjadi badgeCount (int) supaya bisa tampilkan angka asli.
class _QuickItem extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  const _QuickItem({
    required this.icon,
    required this.bgColor,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withOpacity( 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: badgeCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: badgeCount > 9 ? BorderRadius.circular(9) : null,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slate,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder saat belum ada laporan sama sekali — murni tampilan,
// muncul otomatis kalau recentReports kosong (logic tidak diubah).
class _EmptyReportsPlaceholder extends StatelessWidget {
  const _EmptyReportsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 34, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(
            'Belum ada laporan',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}