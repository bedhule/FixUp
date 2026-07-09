import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fixup_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reports(
        id TEXT PRIMARY KEY,
        title TEXT,
        location TEXT,
        building TEXT,
        floor TEXT,
        category TEXT,
        urgency TEXT,
        status TEXT,
        description TEXT,
        createdAt TEXT,
        reporterCount INTEGER,
        rating REAL,
        imagePath TEXT,
        history TEXT
      )
    ''');
    
    // Seed initial data
    for (var report in sampleReports) {
      await db.insert('reports', report.toMap());
    }
  }

  Future<int> insertReport(Report report) async {
    final db = await database;
    return await db.insert('reports', report.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Report>> getReports() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reports', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) {
      return Report.fromMap(maps[i]);
    });
  }

  Future<int> updateReport(Report report) async {
    final db = await database;
    return await db.update(
      'reports',
      report.toMap(),
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }

  Future<int> deleteReport(String id) async {
    final db = await database;
    return await db.delete(
      'reports',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
