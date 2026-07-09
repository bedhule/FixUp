import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import 'login_screen.dart';
import 'pelapor/detail_screen.dart';

class PublikScreen extends StatefulWidget {
  const PublikScreen({super.key});

  @override
  State<PublikScreen> createState() => _PublikScreenState();
}

class _PublikScreenState extends State<PublikScreen> {
  String _filterBuilding = 'Semua';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<Report> _filtered(List<Report> reports) {
    var result = reports;
    if (_filterBuilding != 'Semua') {
      result = result.where((r) => r.building == _filterBuilding).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((r) =>
        r.title.toLowerCase().contains(q) ||
        r.location.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  List<String> get _buildings {
    final provider = context.read<ReportProvider>();
    return provider.reports.map((r) => r.building).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final allReports = provider.reports;
    final filteredReports = _filtered(allReports);
    final selesai = allReports.where((r) => r.status == ReportStatus.selesai).length;
    final diproses = allReports.where((r) => r.status == ReportStatus.diproses).length;
    final diterima = allReports.where((r) => r.status == ReportStatus.diterima).length;
    final darurat = allReports.where((r) => r.status == ReportStatus.darurat).length;
    final total = allReports.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Papan Transparansi'),
        backgroundColor: AppColors.white,
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ringkasan status perbaikan fasilitas kampus — dapat diakses tanpa login.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.primary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SectionLabel('Statistik Bulan Ini'),
            Row(
              children: [
                Expanded(child: StatCard(value: '$diterima', label: 'Diterima', valueColor: AppColors.amber)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(value: '$diproses', label: 'Diproses', valueColor: AppColors.blue)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(value: '$selesai', label: 'Selesai', valueColor: AppColors.green)),
              ],
            ),

            const SectionLabel('Grafik Penyelesaian'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total $total laporan · $selesai selesai',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 18,
                      child: Row(
                        children: [
                          if (diterima > 0)
                            Expanded(
                              flex: diterima,
                              child: Container(color: AppColors.amber),
                            ),
                          if (diproses > 0)
                            Expanded(
                              flex: diproses,
                              child: Container(color: AppColors.blue),
                            ),
                          if (selesai > 0)
                            Expanded(
                              flex: selesai,
                              child: Container(color: AppColors.green),
                            ),
                          if (darurat > 0)
                            Expanded(
                              flex: darurat,
                              child: Container(color: AppColors.red),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      _Legend(color: AppColors.amber, label: 'Diterima'),
                      SizedBox(width: 12),
                      _Legend(color: AppColors.primary, label: 'Diproses'),
                      SizedBox(width: 12),
                      _Legend(color: AppColors.green, label: 'Selesai'),
                      SizedBox(width: 12),
                      _Legend(color: AppColors.red, label: 'Darurat'),
                    ],
                  ),
                ],
              ),
            ),

            const SectionLabel('Filter & Cari'),
            // Search
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari laporan...',
                  hintStyle: GoogleFonts.inter(color: AppColors.muted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            // Building filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', ..._buildings].map((b) {
                  final sel = _filterBuilding == b;
                  return GestureDetector(
                    onTap: () => setState(() => _filterBuilding = b),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.navy : AppColors.white,
                        border: Border.all(color: sel ? AppColors.navy : AppColors.line, width: 1.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(b, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.slate)),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SectionLabel('Laporan Terbaru'),
            ...filteredReports.map((r) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(report: r)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                            const SizedBox(height: 3),
                            Text(r.location, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      StatusBadge(status: r.status),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.primary, size: 28),
                  const SizedBox(height: 8),
                  Text('Punya akun kampus?', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text('Masuk untuk melapor kerusakan atau mengelola laporan.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted), textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Masuk ke Aplikasi',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    icon: Icons.login,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}
