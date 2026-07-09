import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { diterima, diproses, selesai, darurat }
enum ReportCategory { ac, listrik, proyektor, furnitur, toilet, lainnya }
enum UrgencyLevel { ringan, sedang, darurat }
enum UserRole { pelapor, sarpras }

extension ReportStatusExt on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.diterima:
        return 'Diterima';
      case ReportStatus.diproses:
        return 'Diproses';
      case ReportStatus.selesai:
        return 'Selesai';
      case ReportStatus.darurat:
        return 'Darurat';
    }
  }
}

extension ReportCategoryExt on ReportCategory {
  String get label {
    switch (this) {
      case ReportCategory.ac:
        return 'AC';
      case ReportCategory.listrik:
        return 'Listrik/Lampu';
      case ReportCategory.proyektor:
        return 'Proyektor';
      case ReportCategory.furnitur:
        return 'Furnitur';
      case ReportCategory.toilet:
        return 'Toilet';
      case ReportCategory.lainnya:
        return 'Lainnya';
    }
  }
}

extension UrgencyExt on UrgencyLevel {
  String get label {
    switch (this) {
      case UrgencyLevel.ringan:
        return 'Ringan';
      case UrgencyLevel.sedang:
        return 'Sedang';
      case UrgencyLevel.darurat:
        return 'Darurat';
    }
  }
}

class Report {
  final String id;
  final String title;
  final String location;
  final String building;
  final String floor;
  final ReportCategory category;
  final UrgencyLevel urgency;
  final ReportStatus status;
  final String description;
  final DateTime createdAt;
  final int reporterCount;
  final double? rating;
  final String? imagePath;
  final String? userId;
  final String? feedback;
  final String? reporterName;
  final List<StatusHistory> history;

  Report({
    required this.id,
    required this.title,
    required this.location,
    required this.building,
    required this.floor,
    required this.category,
    required this.urgency,
    required this.status,
    required this.description,
    required this.createdAt,
    this.reporterCount = 1,
    this.rating,
    this.imagePath,
    this.userId,
    this.feedback,
    this.reporterName,
    required this.history,
  });

  Report copyWith({ReportStatus? status, double? rating, String? feedback, List<StatusHistory>? history, String? imagePath, String? reporterName}) {
    return Report(
      id: id,
      title: title,
      location: location,
      building: building,
      floor: floor,
      category: category,
      urgency: urgency,
      status: status ?? this.status,
      description: description,
      createdAt: createdAt,
      reporterCount: reporterCount,
      rating: rating ?? this.rating,
      imagePath: imagePath ?? this.imagePath,
      userId: userId,
      feedback: feedback ?? this.feedback,
      reporterName: reporterName ?? this.reporterName,
      history: history ?? this.history,
    );
  }

  // SQLite legacy
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'building': building,
      'floor': floor,
      'category': category.name,
      'urgency': urgency.name,
      'status': status.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'reporterCount': reporterCount,
      'rating': rating,
      'imagePath': imagePath,
      'history': jsonEncode(history.map((h) => h.toMap()).toList()),
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    var historyList = jsonDecode(map['history']) as List;
    return Report(
      id: map['id'],
      title: map['title'],
      location: map['location'],
      building: map['building'],
      floor: map['floor'],
      category: ReportCategory.values.firstWhere((e) => e.name == map['category']),
      urgency: UrgencyLevel.values.firstWhere((e) => e.name == map['urgency']),
      status: ReportStatus.values.firstWhere((e) => e.name == map['status']),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      reporterCount: map['reporterCount'] ?? 1,
      rating: map['rating'],
      imagePath: map['imagePath'],
      history: historyList.map((h) => StatusHistory.fromMap(h)).toList(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'location': location,
      'building': building,
      'floor': floor,
      'category': category.name,
      'urgency': urgency.name,
      'status': status.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'reporterCount': reporterCount,
      'rating': rating,
      'imagePath': imagePath,
      'userId': userId,
      'feedback': feedback,
      'reporterName': reporterName,
      'history': history.map((h) => h.toFirestoreMap()).toList(),
    };
  }

  factory Report.fromFirestoreMap(Map<String, dynamic> map, String docId) {
    return Report(
      id: docId,
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      building: map['building'] ?? '',
      floor: map['floor'] ?? '',
      category: ReportCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ReportCategory.lainnya,
      ),
      urgency: UrgencyLevel.values.firstWhere(
        (e) => e.name == map['urgency'],
        orElse: () => UrgencyLevel.ringan,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.diterima,
      ),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] is String)
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reporterCount: map['reporterCount'] ?? 1,
      rating: (map['rating'] as num?)?.toDouble(),
      imagePath: map['imagePath'],
      userId: map['userId'],
      feedback: map['feedback'],
      reporterName: map['reporterName'],
      history: (map['history'] as List<dynamic>?)
              ?.map((h) => StatusHistory.fromFirestoreMap(h as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}



class StatusHistory {
  final ReportStatus status;
  final DateTime time;
  final String note;

  StatusHistory({required this.status, required this.time, required this.note});

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'time': time.toIso8601String(),
        'note': note,
      };

  factory StatusHistory.fromMap(Map<String, dynamic> map) => StatusHistory(
        status: ReportStatus.values.firstWhere((e) => e.name == map['status']),
        time: DateTime.parse(map['time']),
        note: map['note'],
      );

  Map<String, dynamic> toFirestoreMap() => {
        'status': status.name,
        'time': time.toIso8601String(),
        'note': note,
      };

  factory StatusHistory.fromFirestoreMap(Map<String, dynamic> map) => StatusHistory(
        status: ReportStatus.values.firstWhere((e) => e.name == map['status']),
        time: (map['time'] is String)
            ? DateTime.parse(map['time'])
            : (map['time'] as Timestamp).toDate(),
        note: map['note'] ?? '',
      );
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String? userId;

  AppNotification({
    this.id = '',
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.userId,
  });

  Map<String, dynamic> toFirestoreMap() => {
        'title': title,
        'message': message,
        'time': time.toIso8601String(),
        'isRead': isRead,
        'userId': userId,
      };

  factory AppNotification.fromFirestoreMap(Map<String, dynamic> map, String docId) =>
      AppNotification(
        id: docId,
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        time: (map['time'] is String)
            ? DateTime.parse(map['time'])
            : (map['time'] as Timestamp).toDate(),
        isRead: map['isRead'] ?? false,
        userId: map['userId'],
      );
}

// Sample data
List<Report> sampleReports = [
  Report(
    id: '001',
    title: 'AC Ruang B.301 mati',
    location: 'Gedung B · Ruang 301',
    building: 'Gedung B',
    floor: 'Lt. 3',
    category: ReportCategory.ac,
    urgency: UrgencyLevel.sedang,
    status: ReportStatus.diproses,
    description: 'AC di ruang B.301 tidak menyala sejak pagi. Ruangan menjadi panas dan mengganggu aktivitas perkuliahan.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    reporterCount: 3,
    history: [
      StatusHistory(
        status: ReportStatus.diterima,
        time: DateTime.now().subtract(const Duration(days: 2)),
        note: 'Laporan masuk ke sistem',
      ),
      StatusHistory(
        status: ReportStatus.diproses,
        time: DateTime.now().subtract(const Duration(days: 1)),
        note: 'Staf Sarpras menindaklanjuti',
      ),
    ],
  ),
  Report(
    id: '002',
    title: 'Proyektor Lab Mobile',
    location: 'Gedung C · Lab Mobile',
    building: 'Gedung C',
    floor: 'Lt. 2',
    category: ReportCategory.proyektor,
    urgency: UrgencyLevel.ringan,
    status: ReportStatus.selesai,
    description: 'Proyektor tidak dapat terhubung ke laptop via HDMI.',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    rating: 4.5,
    history: [
      StatusHistory(
        status: ReportStatus.diterima,
        time: DateTime.now().subtract(const Duration(days: 5)),
        note: 'Laporan masuk ke sistem',
      ),
      StatusHistory(
        status: ReportStatus.diproses,
        time: DateTime.now().subtract(const Duration(days: 4)),
        note: 'Teknisi dijadwalkan',
      ),
      StatusHistory(
        status: ReportStatus.selesai,
        time: DateTime.now().subtract(const Duration(days: 3)),
        note: 'Kabel HDMI diganti, proyektor berfungsi normal',
      ),
    ],
  ),
  Report(
    id: '003',
    title: 'Kursi patah R. C.205',
    location: 'Gedung C · Ruang 205',
    building: 'Gedung C',
    floor: 'Lt. 2',
    category: ReportCategory.furnitur,
    urgency: UrgencyLevel.ringan,
    status: ReportStatus.diterima,
    description: 'Terdapat 2 kursi yang kakinya patah, berbahaya jika digunakan.',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    history: [
      StatusHistory(
        status: ReportStatus.diterima,
        time: DateTime.now().subtract(const Duration(hours: 3)),
        note: 'Laporan masuk ke sistem',
      ),
    ],
  ),
  Report(
    id: '004',
    title: 'Lampu koridor A mati',
    location: 'Gedung A · Koridor Lt. 1',
    building: 'Gedung A',
    floor: 'Lt. 1',
    category: ReportCategory.listrik,
    urgency: UrgencyLevel.sedang,
    status: ReportStatus.selesai,
    description: 'Lampu di sepanjang koridor lantai 1 gedung A tidak menyala.',
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    rating: 5.0,
    history: [
      StatusHistory(
        status: ReportStatus.diterima,
        time: DateTime.now().subtract(const Duration(days: 14)),
        note: 'Laporan masuk ke sistem',
      ),
      StatusHistory(
        status: ReportStatus.diproses,
        time: DateTime.now().subtract(const Duration(days: 13)),
        note: 'Tim elektrik diturunkan',
      ),
      StatusHistory(
        status: ReportStatus.selesai,
        time: DateTime.now().subtract(const Duration(days: 12)),
        note: 'Lampu berhasil diperbaiki',
      ),
    ],
  ),
  Report(
    id: '005',
    title: 'Korsleting panel listrik Lt.1',
    location: 'Gedung A · Panel Listrik',
    building: 'Gedung A',
    floor: 'Lt. 1',
    category: ReportCategory.listrik,
    urgency: UrgencyLevel.darurat,
    status: ReportStatus.darurat,
    description: 'Panel listrik di lantai 1 gedung A mengeluarkan percikan api. Berbahaya!',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    history: [
      StatusHistory(
        status: ReportStatus.diterima,
        time: DateTime.now().subtract(const Duration(hours: 1)),
        note: 'Laporan darurat masuk',
      ),
    ],
  ),
];

List<AppNotification> sampleNotifications = [
  AppNotification(
    title: 'Status diperbarui',
    message: 'Laporan "AC Ruang B.301" kini sedang Diproses oleh Staf Sarpras.',
    time: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AppNotification(
    title: 'Laporan selesai',
    message: '"Proyektor Lab Mobile" telah diperbaiki. Beri rating penanganan sekarang.',
    time: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
  ),
  AppNotification(
    title: 'Tips fasilitas',
    message: 'Yuk bantu jaga fasilitas kampus tetap baik! Laporkan kerusakan sesegera mungkin 🙌',
    time: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
  ),
];
