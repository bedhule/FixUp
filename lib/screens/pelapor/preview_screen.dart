import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../firebase/firebase_helper.dart';
import 'sukses_screen.dart';

class PreviewScreen extends StatefulWidget {
  final Report report;

  const PreviewScreen({super.key, required this.report});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _sending = false;

  Future<void> _submit() async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final helper = FirebaseHelper();
      final uid = helper.currentUser?.uid;
      final user = helper.currentUser;

      String? imageUrl = widget.report.imagePath;
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        imageUrl = await helper.uploadReportImage(widget.report.id, imageUrl);
      }

      final reportWithUrl = widget.report.copyWith(
        imagePath: imageUrl,
      );

      final userName = user?.displayName ?? '';
      final reportWithUser = Report(
        id: reportWithUrl.id,
        title: reportWithUrl.title,
        location: reportWithUrl.location,
        building: reportWithUrl.building,
        floor: reportWithUrl.floor,
        category: reportWithUrl.category,
        urgency: reportWithUrl.urgency,
        status: reportWithUrl.status,
        description: reportWithUrl.description,
        createdAt: reportWithUrl.createdAt,
        reporterCount: reportWithUrl.reporterCount,
        rating: reportWithUrl.rating,
        imagePath: reportWithUrl.imagePath,
        userId: uid,
        reporterName: userName,
        history: reportWithUrl.history,
      );

      final reportProvider = context.read<ReportProvider>();
      final navigator = Navigator.of(context);
      await reportProvider.addReport(reportWithUser);

      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => SuksesScreen(report: reportWithUser)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preview Laporan'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, Color(0xFFF2FAFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                borderRadius: BorderRadius.circular(16),
                image: (widget.report.imagePath != null && widget.report.imagePath!.isNotEmpty)
                    ? DecorationImage(
                        image: FileImage(File(widget.report.imagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (widget.report.imagePath == null || widget.report.imagePath!.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 36),
                          const SizedBox(height: 6),
                          Text(
                            'Foto kerusakan tersedia',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreviewRow(label: 'Lokasi', value: widget.report.location),
                  const Divider(height: 16, color: AppColors.line),
                  _PreviewRow(label: 'Kategori', value: widget.report.category.label),
                  const Divider(height: 16, color: AppColors.line),
                  _PreviewRow(label: 'Urgensi', value: widget.report.urgency.label),
                  const Divider(height: 16, color: AppColors.line),
                  Text(
                    'Deskripsi',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.report.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.slate,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
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
                    onTap: _sending ? null : _submit,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Kirim Laporan',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
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
            ),
            const SizedBox(height: 8),
            GhostButton(
              label: 'Kembali Edit',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}
