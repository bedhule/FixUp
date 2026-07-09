import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/photo_preview_screen.dart';
import '../../providers/report_provider.dart';
import '../../providers/notification_provider.dart';

class SarprasDetailScreen extends StatefulWidget {
  final Report report;

  const SarprasDetailScreen({super.key, required this.report});

  @override
  State<SarprasDetailScreen> createState() => _SarprasDetailScreenState();
}

class _SarprasDetailScreenState extends State<SarprasDetailScreen> {
  late ReportStatus _selectedStatus;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status == ReportStatus.darurat
        ? ReportStatus.diterima
        : widget.report.status;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final provider = context.read<ReportProvider>();
      final notifProvider = context.read<NotificationProvider>();
      final oldStatus = widget.report.status;
      final updatedHistory = List<StatusHistory>.from(widget.report.history);
      if (_selectedStatus != widget.report.status) {
        updatedHistory.add(StatusHistory(
          status: _selectedStatus,
          time: DateTime.now(),
          note: _noteController.text.isNotEmpty
              ? _noteController.text
              : 'Staf Sarpras menindaklanjuti',
        ));
      }
      final updatedReport = widget.report.copyWith(
        status: _selectedStatus,
        history: updatedHistory,
      );
      if (_selectedStatus != oldStatus) {
        notifProvider.notifyStatusChanged(updatedReport, oldStatus);
      }
      await provider.updateReport(updatedReport);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diperbarui: ${_selectedStatus.label}'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Laporan'),
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
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PhotoPreviewScreen(imagePath: widget.report.imagePath)),
              ),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, Color(0xFFF2FAFA)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 32),
                      const SizedBox(height: 6),
                      Text('Ketuk untuk lihat foto', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.report.title, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 6),
            Text(
              '${widget.report.building} · ${widget.report.floor} · ${widget.report.reporterCount} pelapor · Urgensi ${widget.report.urgency.label}',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(widget.report.description, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate, height: 1.5)),
            ),
            const SectionLabel('Ubah Status'),
            Row(
              children: [
                ReportStatus.diterima,
                ReportStatus.diproses,
                ReportStatus.selesai,
              ].map((s) {
                final sel = _selectedStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStatus = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.navy : AppColors.white,
                        border: Border.all(color: sel ? AppColors.navy : AppColors.line, width: 1.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(s.label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.slate)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SectionLabel('Catatan Penanganan'),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Catatan penanganan (opsional)',
                hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
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
                    onTap: _saving ? null : _save,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _saving
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
                                  'Simpan & Kirim Notifikasi',
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
