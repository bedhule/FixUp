import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import 'sarpras_detail_screen.dart';
import '../publik_screen.dart';
import '../pelapor/notif_screen.dart';
import '../pelapor/profil_screen.dart' as profil;

class SarprasDashboardScreen extends StatefulWidget {
  const SarprasDashboardScreen({super.key});

  @override
  State<SarprasDashboardScreen> createState() => _SarprasDashboardScreenState();
}

class _SarprasDashboardScreenState extends State<SarprasDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _DashboardContent(),
    const PublikScreen(),
    const NotifScreen(),
    const profil.ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', index: 0, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign, label: 'Transparansi', index: 1, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifikasi', index: 2, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', index: 3, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final Function(int) onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primary : AppColors.muted, size: 22),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: isActive ? AppColors.primary : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  String _filter = 'Semua';

  List<Report> _filteredList(BuildContext context) {
    final allReports = context.watch<ReportProvider>().reports;
    if (_filter == 'Semua') return allReports;
    if (_filter == 'Darurat') return allReports.where((r) => r.urgency == UrgencyLevel.darurat).toList();
    return allReports.where((r) => r.building == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allReports = context.watch<ReportProvider>().reports;
    final diterima = allReports.where((r) => r.status == ReportStatus.diterima).length;
    final diproses = allReports.where((r) => r.status == ReportStatus.diproses).length;
    final selesai = allReports.where((r) => r.status == ReportStatus.selesai).length;
    final darurat = allReports.where((r) => r.status == ReportStatus.darurat).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Sarpras'),
        backgroundColor: AppColors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifScreen())),
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: AppColors.navy),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
              children: [
                StatCard(value: '$diterima', label: 'Diterima', valueColor: AppColors.amber),
                StatCard(value: '$diproses', label: 'Diproses', valueColor: AppColors.blue),
                StatCard(value: '$selesai bln ini', label: 'Selesai Bulan Ini', valueColor: AppColors.green),
                StatCard(value: '$darurat ⚠️', label: 'Darurat', valueColor: AppColors.red),
              ],
            ),

            const SectionLabel('Filter'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Gedung A', 'Gedung B', 'Gedung C', 'Darurat'].map((f) {
                  final sel = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.navy : AppColors.white,
                        border: Border.all(color: sel ? AppColors.navy : AppColors.line, width: 1.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(f, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.slate)),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SectionLabel('Laporan Masuk'),
            ..._filteredList(context).map((r) => _SarprasReportCard(
              report: r,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SarprasDetailScreen(report: r))),
            )),
          ],
        ),
      ),
    );
  }
}

class _SarprasReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _SarprasReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEmergency = report.status == ReportStatus.darurat;
    final desc = report.description.length > 80
        ? '${report.description.substring(0, 80)}...'
        : report.description;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: isEmergency ? AppColors.red : AppColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity( 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 12, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.reporterName ?? 'Anonim',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.slate,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
