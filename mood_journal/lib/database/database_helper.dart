import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/journal_entry.dart';
import '../models/coping_strategy.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // ─── Veritabanı Bağlantısı ───
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'mood_journal.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Journal Entries tablosu
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mood_score INTEGER NOT NULL,
        trigger_text TEXT NOT NULL,
        notes TEXT,
        coping_strategy TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Coping Strategies tablosu
    await db.execute('''
      CREATE TABLE coping_strategies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        usage_count INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 0
      )
    ''');

    // Varsayılan stratejileri ekle
    await _seedDefaultStrategies(db);
  }

  Future<void> _seedDefaultStrategies(Database db) async {
    final defaults = CopingStrategy.defaultStrategies;
    for (final strategy in defaults) {
      await db.insert('coping_strategies', strategy.toMap());
    }
  }

  // ═══════════════════════════════════════════
  // JOURNAL ENTRIES - CRUD İşlemleri
  // ═══════════════════════════════════════════

  /// Yeni entry ekle
  Future<int> insertEntry(JournalEntry entry) async {
    final db = await database;
    return await db.insert('journal_entries', entry.toMap());
  }

  /// Entry güncelle
  Future<int> updateEntry(JournalEntry entry) async {
    final db = await database;
    return await db.update(
      'journal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Entry sil
  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Tüm entry'leri getir (en yeniden en eskiye)
  Future<List<JournalEntry>> getEntries() async {
    final db = await database;
    final maps = await db.query(
      'journal_entries',
      orderBy: 'date DESC',
    );
    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Belirli bir entry getir
  Future<JournalEntry?> getEntry(int id) async {
    final db = await database;
    final maps = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }

  /// Tarih aralığına göre entry'leri getir
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'journal_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Son N günün entry'lerini getir
  Future<List<JournalEntry>> getRecentEntries(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - days);
    return getEntriesByDateRange(start, now);
  }

  /// Arama (tetikleyici veya notlarda)
  Future<List<JournalEntry>> searchEntries(String query) async {
    final db = await database;
    final maps = await db.query(
      'journal_entries',
      where: 'trigger_text LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  // ═══════════════════════════════════════════
  // İSTATİSTİK SORGULARI
  // ═══════════════════════════════════════════

  /// Tarih aralığındaki ortalama duygu skoru
  Future<double> getAverageMood(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(mood_score) as avg_mood FROM journal_entries WHERE date >= ? AND date <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final avg = result.first['avg_mood'];
    if (avg == null) return 0.0;
    return (avg as num).toDouble();
  }

  /// Haftalık ortalama mood (son 4 hafta)
  Future<List<Map<String, dynamic>>> getWeeklyAverages() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> weeklyData = [];

    for (int i = 3; i >= 0; i--) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 7));

      final avg = await getAverageMood(weekStart, weekEnd);
      final count = await _getEntryCount(weekStart, weekEnd);

      weeklyData.add({
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'average': avg,
        'count': count,
        'label': 'Hafta ${4 - i}',
      });
    }

    return weeklyData;
  }

  /// Günlük ortalamalar (son N gün)
  Future<List<Map<String, dynamic>>> getDailyAverages(int days) async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> dailyData = [];

    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayEnd = day.add(const Duration(days: 1));

      final db = await database;
      final result = await db.rawQuery(
        'SELECT AVG(mood_score) as avg_mood, COUNT(*) as count FROM journal_entries WHERE date >= ? AND date < ?',
        [day.toIso8601String(), dayEnd.toIso8601String()],
      );

      final avg = result.first['avg_mood'];
      final count = result.first['count'] as int;

      dailyData.add({
        'date': day,
        'average': avg != null ? (avg as num).toDouble() : 0.0,
        'count': count,
      });
    }

    return dailyData;
  }

  Future<int> _getEntryCount(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_entries WHERE date >= ? AND date <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return result.first['count'] as int;
  }

  /// En sık tetikleyiciler
  Future<List<Map<String, dynamic>>> getTopTriggers({int limit = 5}) async {
    final db = await database;
    final entries = await db.query('journal_entries');

    // Tetikleyicileri say
    final Map<String, int> triggerCounts = {};
    for (final entry in entries) {
      final trigger = entry['trigger_text'] as String;
      if (trigger.isNotEmpty) {
        triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
      }
    }

    // Sırala ve limit uygula
    final sorted = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(limit)
        .map((e) => {'trigger': e.key, 'count': e.value})
        .toList();
  }

  /// Toplam entry sayısı
  Future<int> getTotalEntryCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_entries',
    );
    return result.first['count'] as int;
  }

  // ═══════════════════════════════════════════
  // COPING STRATEGIES - CRUD İşlemleri
  // ═══════════════════════════════════════════

  /// Tüm stratejileri getir
  Future<List<CopingStrategy>> getStrategies() async {
    final db = await database;
    final maps = await db.query(
      'coping_strategies',
      orderBy: 'usage_count DESC',
    );
    return maps.map((map) => CopingStrategy.fromMap(map)).toList();
  }

  /// Yeni strateji ekle
  Future<int> insertStrategy(CopingStrategy strategy) async {
    final db = await database;
    return await db.insert('coping_strategies', strategy.toMap());
  }

  /// Strateji sil
  Future<int> deleteStrategy(int id) async {
    final db = await database;
    return await db.delete(
      'coping_strategies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Kullanım sayısını artır
  Future<void> incrementStrategyUsage(String name) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE coping_strategies SET usage_count = usage_count + 1 WHERE name = ?',
      [name],
    );
  }

  /// En çok kullanılan stratejiler
  Future<List<CopingStrategy>> getTopStrategies({int limit = 5}) async {
    final db = await database;
    final maps = await db.query(
      'coping_strategies',
      where: 'usage_count > 0',
      orderBy: 'usage_count DESC',
      limit: limit,
    );
    return maps.map((map) => CopingStrategy.fromMap(map)).toList();
  }

  // ═══════════════════════════════════════════
  // VERİTABANI YÖNETİMİ
  // ═══════════════════════════════════════════

  /// Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
