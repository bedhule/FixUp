import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import 'detail_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  ReportStatus? _filterStatus;

  List<Report> _filtered(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final allReports = provider.reports;
    if (_filterStatus == null) return allReports;
    return allReports.where((r) => r.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filtered(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gradient header
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        'Riwayat Laporan',
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Filter chips
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'Semua', selected: _filterStatus == null, onTap: () => setState(() => _filterStatus = null)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Diterima', selected: _filterStatus == ReportStatus.diterima, onTap: () => setState(() => _filterStatus = ReportStatus.diterima)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Diproses', selected: _filterStatus == ReportStatus.diproses, onTap: () => setState(() => _filterStatus = ReportStatus.diproses)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Selesai', selected: _filterStatus == ReportStatus.selesai, onTap: () => setState(() => _filterStatus = ReportStatus.selesai)),
                ],
              ),
            ),
          ),
          // Report list
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 56, color: AppColors.line),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada laporan',
                          style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, i) {
                      final r = filteredList[i];
                      return ReportCard(
                        report: r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailScreen(report: r)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.slate,
          ),
        ),
      ),
    );
  }
}
