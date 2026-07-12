import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/photo_preview_screen.dart';
import 'rating_screen.dart';

class DetailScreen extends StatelessWidget {
  final Report report;

  const DetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, HH:mm', 'id_ID');
    print("===== DETAIL SCREEN =====");
print(report.imagePath);
print(report.imagePath?.startsWith("http"));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoPreviewScreen(
          imagePath: report.imagePath,
        ),
      ),
    );
  },
  child: Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    height: 180,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.primaryLight,
    ),
    clipBehavior: Clip.antiAlias,
    child: report.imagePath != null &&
            report.imagePath!.isNotEmpty
        ? report.imagePath!.startsWith("http")
            ? Image.network(
                report.imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 40),
                ),
              )
            : Image.file(
                File(report.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 40),
                ),
              )
        : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  "Belum ada foto",
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
  ),
),
            const SizedBox(height: 16),
            // Title & badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusBadge(status: report.status),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${report.building} · ${report.floor} · Kategori: ${report.category.label} · Urgensi: ${report.urgency.label}',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 18),
            // Deskripsi
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionLabel('Deskripsi'),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report.description,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate, height: 1.5),
              ),
            ),
            // Status Penanganan
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionLabel('Status Penanganan'),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: _buildTimeline(report, fmt),
              ),
            ),
            // Rating button (gradient, same as Login Masuk)
            if (report.status == ReportStatus.selesai) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.buttonTop, AppColors.primary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity( 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: report.rating == null
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RatingScreen(report: report)),
                                )
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: Text(
                            report.rating != null
                                ? '⭐ Sudah Dinilai (${report.rating})'
                                : 'Beri Rating Penanganan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeline(Report report, DateFormat fmt) {
    final allStatuses = [ReportStatus.diterima, ReportStatus.diproses, ReportStatus.selesai];
    final widgets = <Widget>[];

    for (int i = 0; i < allStatuses.length; i++) {
      final s = allStatuses[i];
      final historyItem = report.history.where((h) => h.status == s).firstOrNull;
      final isDone = historyItem != null;
      final isLast = i == allStatuses.length - 1;

      widgets.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.primary : AppColors.line,
                      border: Border.all(
                        color: isDone ? AppColors.primaryLight : AppColors.background,
                        width: 3,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.line,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDone ? AppColors.navy : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDone
                            ? '${fmt.format(historyItem.time)} — ${historyItem.note}'
                            : 'Menunggu konfirmasi',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}
