import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../firebase/firebase_helper.dart';
import 'notification_provider.dart'; // TAMBAHAN

class ReportProvider with ChangeNotifier {
  List<Report> _reports = [];
  bool _isLoading = true;

  // TAMBAHAN: referensi ke NotificationProvider, di-set dari main.dart lewat ProxyProvider
  NotificationProvider? _notificationProvider;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;

  // TAMBAHAN: dipanggil otomatis oleh ChangeNotifierProxyProvider di main.dart
  void updateNotificationProvider(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }

  ReportProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      FirebaseHelper().getReportsStream().listen((list) {
        _reports = list;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[ReportProvider] Stream error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();
    try {
      _reports = await FirebaseHelper().getReports();
    } catch (e) {
      debugPrint('[ReportProvider] loadReports error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addReport(Report report) async {
    try {
      await FirebaseHelper().saveReport(report);
      _notificationProvider?.notifyReportCreated(report); // TAMBAHAN
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReport(Report report) async {
    try {
      // TAMBAHAN: simpan status lama sebelum di-update, untuk dibandingkan setelahnya
      final oldReport = _reports.firstWhere(
        (r) => r.id == report.id,
        orElse: () => report,
      );
      await FirebaseHelper().updateReport(report);
      if (oldReport.status != report.status) {
        _notificationProvider?.notifyStatusChanged(report, oldReport.status); // TAMBAHAN
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      await FirebaseHelper().deleteReport(id);
    } catch (e) {
      rethrow;
    }
  }
}