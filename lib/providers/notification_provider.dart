import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../firebase/firebase_helper.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    final uid = FirebaseHelper().currentUser?.uid;
    if (uid != null) {
      FirebaseHelper().getNotificationsStream(uid).listen(
        (list) {
          _notifications = list;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[NotificationProvider] Stream error: $e');
        },
      );
    } else {
      _notifications = List.from(sampleNotifications);
      notifyListeners();
    }
  }

  void addNotification(AppNotification notif, {String? targetUserId}) {
    // FIX: kirim ke targetUserId (misalnya pemilik laporan) kalau diberikan,
    // jangan selalu pakai currentUser (bisa jadi Sarpras yang sedang login, bukan Pelapor).
    final destinationUid = targetUserId ?? FirebaseHelper().currentUser?.uid;
    if (destinationUid != null) {
      FirebaseHelper().addNotification(
        AppNotification(
          title: notif.title,
          message: notif.message,
          time: notif.time,
          userId: destinationUid,
        ),
      );
    } else {
      _notifications.insert(0, notif);
      notifyListeners();
    }
  }

  void markAsRead(String notifId) {
    final uid = FirebaseHelper().currentUser?.uid;
    if (uid != null) {
      FirebaseHelper().markNotificationRead(notifId);
    } else {
      final idx = _notifications.indexWhere((n) => n.id == notifId);
      if (idx != -1) {
        final old = _notifications[idx];
        _notifications[idx] = AppNotification(
          id: old.id,
          title: old.title,
          message: old.message,
          time: old.time,
          userId: old.userId,
          isRead: true,
        );
        notifyListeners();
      }
    }
  }

  void markAllRead() {
    final uid = FirebaseHelper().currentUser?.uid;
    if (uid != null) {
      FirebaseHelper().markAllNotificationsRead(uid);
    } else {
      final updated = _notifications.map((n) => AppNotification(
        id: n.id, // FIX: pertahankan id asli, jangan buat id baru
        title: n.title,
        message: n.message,
        time: n.time,
        userId: n.userId, // FIX: pertahankan userId asli
        isRead: true,
      )).toList();
      _notifications = updated;
      notifyListeners();
    }
  }

  void notifyReportCreated(Report report) {
    final msg = '"${report.title}" telah diterima. Pantau status perbaikannya.';
    addNotification(
      AppNotification(
        title: 'Laporan baru dikirim',
        message: msg,
        time: DateTime.now(),
      ),
    );
  }

  void notifyStatusChanged(Report report, ReportStatus oldStatus) {
    final msg = 'Laporan "${report.title}" berubah dari ${oldStatus.label} menjadi ${report.status.label}.';
    addNotification(
      AppNotification(
        title: 'Status diperbarui',
        message: msg,
        time: DateTime.now(),
      ),
      // FIX: notifikasi harus sampai ke Pelapor (pemilik laporan),
      // bukan ke Sarpras yang sedang login dan mengubah status.
      targetUserId: report.userId,
    );
  }
}