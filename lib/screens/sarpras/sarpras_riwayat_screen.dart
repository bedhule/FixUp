import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/report_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'sarpras_detail_screen.dart';

class SarprasRiwayatScreen extends StatefulWidget {
  const SarprasRiwayatScreen({super.key});

  @override
  State<SarprasRiwayatScreen> createState() =>
      _SarprasRiwayatScreenState();
}

class _SarprasRiwayatScreenState
    extends State<SarprasRiwayatScreen> {
  String _filter = "Semua";

  List<Report> _filteredReports(List<Report> reports) {
    switch (_filter) {
      case "Diterima":
        return reports
            .where((r) => r.status == ReportStatus.diterima)
            .toList();

      case "Diproses":
        return reports
            .where((r) => r.status == ReportStatus.diproses)
            .toList();

      case "Selesai":
        return reports
            .where((r) => r.status == ReportStatus.selesai)
            .toList();

      case "Darurat":
        return reports
            .where((r) => r.status == ReportStatus.darurat)
            .toList();

      default:
        return reports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = List<Report>.from(
      context.watch<ReportProvider>().reports,
    );

    reports.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    final filtered = _filteredReports(reports);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Riwayat Laporan"),
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.line,
          ),
        ),
      ),
      body: Column(
        children: [

          /// FILTER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  "Semua",
                  "Diterima",
                  "Diproses",
                  "Selesai",
                  "Darurat"
                ].map((item) {
                  final selected = _filter == item;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _filter = item;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.line,
                        ),
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.slate,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada laporan.",
                      style: GoogleFonts.inter(
                        color: AppColors.muted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final report = filtered[index];

                      final emergency =
                          report.status ==
                              ReportStatus.darurat;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SarprasDetailScreen(
                                      report: report),
                            ),
                          );
                        },
                        child: Container(
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: emergency
                                  ? AppColors.red
                                  : AppColors.line,
                              width: emergency ? 1.6 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      report.title,
                                      style:
                                          GoogleFonts.manrope(
                                        fontWeight:
                                            FontWeight.w700,
                                        fontSize: 15,
                                        color:
                                            AppColors.navy,
                                      ),
                                    ),
                                  ),
                                  StatusBadge(
                                    status: report.status,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color:
                                        AppColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      report.reporterName ??
                                          "Anonim",
                                      style:
                                          GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors
                                            .muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .location_on_outlined,
                                    size: 14,
                                    color:
                                        AppColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      report.location,
                                      style:
                                          GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors
                                            .muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                report.description,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: AppColors.slate,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
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