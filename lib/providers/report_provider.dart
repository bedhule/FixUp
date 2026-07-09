import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../firebase/firebase_helper.dart';

class ReportProvider with ChangeNotifier {
  List<Report> _reports = [];
  bool _isLoading = true;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;

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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReport(Report report) async {
    try {
      await FirebaseHelper().updateReport(report);
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
