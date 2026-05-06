import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/journal_entry.dart';
import '../models/coping_strategy.dart';
import '../models/ai_suggestion.dart';
import '../models/motivation_message.dart';

/// Mood Journal uygulamasının merkezi veritabanı yönetim sınıfı.
///
/// Singleton pattern ile tek bir örnek üzerinden çalışır.
/// Tüm CRUD operasyonları try-catch ile korunmuştur.
/// SQLite PRAGMA ayarları (foreign_keys, WAL) otomatik yapılandırılır.
class DatabaseHelper {
  // ═══════════════════════════════════════════════════════════════
  // SINGLETON & YAPILANDIRMA
  // ═══════════════════════════════════════════════════════════════

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  /// Veritabanı dosya adı.
  static const String _dbName = 'mood_journal.db';

  /// Veritabanı şema versiyonu. Migration'larda artırılır.
  static const int _dbVersion = 1;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  /// Veritabanı bağlantısını döndürür, gerekirse başlatır.
  ///
  /// İlk çağrıda [_initDatabase] ile veritabanı oluşturulur.
  /// Sonraki çağrılarda önbelleğe alınmış instance döner.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Veritabanını başlatır ve yapılandırır.
  Future<Database> _initDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, _dbName);

      return await openDatabase(
        path,
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('═══ VERİTABANI BAŞLATMA HATASI ═══\n$e');
      rethrow;
    }
  }

  /// PRAGMA ayarlarını yapılandırır.
  ///
  /// - `foreign_keys = ON`: FK kısıtlamalarını aktif eder.
  /// - `journal_mode = WAL`: Yazma performansını artırır.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');
  }

  /// Veritabanı ilk kez oluşturulduğunda çalışır.
  ///
  /// Tablo şemalarını oluşturur ve seed data ekler.
  Future<void> _onCreate(Database db, int version) async {
    // ── Tablo oluşturma ──
    await _createJournalEntriesTable(db);
    await _createCopingStrategiesTable(db);
    await _createAiSuggestionsTable(db);
    await _createMotivationMessagesTable(db);

    // ── Başlangıç verileri (seed data) ──
    await _seedDefaultStrategies(db);
    await _seedAiSuggestions(db);
    await _seedMotivationMessages(db);

    debugPrint('✅ Veritabanı başarıyla oluşturuldu (v$version)');
  }

  /// Veritabanı versiyonu yükseltildiğinde çalışır.
  ///
  /// Şu an v1 olduğu için boş. Gelecek migration'lar buraya eklenecek.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('📦 DB Migration: v$oldVersion → v$newVersion');
    // Gelecek migration'lar:
    // if (oldVersion < 2) { await _migrateV1toV2(db); }
  }

  // ═══════════════════════════════════════════════════════════════
  // TABLO ŞEMALARI
  // ═══════════════════════════════════════════════════════════════

  Future<void> _createJournalEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mood_score INTEGER NOT NULL CHECK(mood_score BETWEEN 1 AND 10),
        trigger_text TEXT NOT NULL,
        notes TEXT,
        coping_strategy TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
        updated_at TEXT
      )
    ''');
    // Tarih bazlı sorgular için index
    await db.execute(
      'CREATE INDEX idx_journal_date ON journal_entries(date DESC)',
    );
  }

  Future<void> _createCopingStrategiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE coping_strategies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        usage_count INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createAiSuggestionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ai_suggestions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood_category TEXT NOT NULL CHECK(mood_category IN ('Düşük','Orta','Yüksek')),
        suggestion_text TEXT NOT NULL,
        priority_level INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _createMotivationMessagesTable(Database db) async {
    await db.execute('''
      CREATE TABLE motivation_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_of_week TEXT NOT NULL,
        message_text TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
      )
    ''');
  }

  // ═══════════════════════════════════════════════════════════════
  // SEED DATA — Başlangıç Verileri
  // ═══════════════════════════════════════════════════════════════

  /// Varsayılan coping stratejilerini ekler.
  Future<void> _seedDefaultStrategies(Database db) async {
    final batch = db.batch();
    for (final strategy in CopingStrategy.defaultStrategies) {
      batch.insert('coping_strategies', strategy.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// MySQL dump'taki ai_suggestions verilerini ekler.
  Future<void> _seedAiSuggestions(Database db) async {
    final suggestions = <Map<String, dynamic>>[
      {'mood_category': 'Düşük', 'suggestion_text': 'Şu an çok zorlanıyor olabilirsin, seni anlıyorum. Çevrene odaklanmayı dene.', 'priority_level': 1},
      {'mood_category': 'Düşük', 'suggestion_text': 'Eğer bu düşük ruh hali bir süredir devam ediyorsa birileriyle konuşmak sana iyi gelebilir.', 'priority_level': 1},
      {'mood_category': 'Düşük', 'suggestion_text': 'Derin bir nefes al ve gözlerini kapat, rahatlamaya çalış.', 'priority_level': 2},
      {'mood_category': 'Orta', 'suggestion_text': 'Kafanı dağıtmak için sevdiğin bir şarkıyı açıp kısa bir yürüyüş yapmaya ne dersin?', 'priority_level': 2},
      {'mood_category': 'Orta', 'suggestion_text': 'Bugün seni tetikleyen şeyi yazmak ister misin?', 'priority_level': 2},
      {'mood_category': 'Orta', 'suggestion_text': 'Bir bardak su iç ve yükünü bırak.', 'priority_level': 3},
      {'mood_category': 'Yüksek', 'suggestion_text': 'Harikasın! Bu enerjiyi bugün bir arkadaşına teşekkür ederek paylaşmaya ne dersin?', 'priority_level': 3},
      {'mood_category': 'Yüksek', 'suggestion_text': 'Günün en güzel anını not etmek ister misin?.', 'priority_level': 3},
      {'mood_category': 'Yüksek', 'suggestion_text': 'Kendini bu kadar iyi hissederken uzun zamandır ertelediğin o yaratıcı işe başlamanın tam sırası!', 'priority_level': 3},
    ];
    final batch = db.batch();
    for (final s in suggestions) {
      batch.insert('ai_suggestions', s);
    }
    await batch.commit(noResult: true);
  }

  /// MySQL dump'taki motivation_messages verilerini ekler.
  Future<void> _seedMotivationMessages(Database db) async {
    final messages = <Map<String, dynamic>>[
      {'day_of_week': 'Pazartesi', 'message_text': 'Yeni bir hafta, yeni bir başlangıç. Bugün kendine nazik davranmayı ve küçük adımların gücüne inanmayı unutma.'},
      {'day_of_week': 'Salı', 'message_text': 'Duyguların bir deniz gibidir; bazen dalgalı, bazen durgun. Her iki hali de kabul etmek büyümenin bir parçasıdır.'},
      {'day_of_week': 'Çarşamba', 'message_text': 'Haftanın ortasındasın. Şimdiye kadar başardıklarını fark et ve kendine bir mola vermek için alan tanı.'},
      {'day_of_week': 'Perşembe', 'message_text': 'İçindeki güç, karşılaştığın zorluklardan çok daha büyüktür. Bugün sadece nefes al ve anda kalmaya odaklan.'},
      {'day_of_week': 'Cuma', 'message_text': 'Haftayı bitirirken kendine şu soruyu sor: Bugün ruhuma iyi gelecek ne yapabilirim? Küçük bir yürüyüş ya da sıcak bir çay?'},
      {'day_of_week': 'Cumartesi', 'message_text': 'Dinlenmek bir lüks değil, bir ihtiyaçtır. Bugün zihnini sustur ve sadece var olmanın tadını çıkar.'},
      {'day_of_week': 'Pazar', 'message_text': 'Yeni haftaya hazırlanırken geçmiş günlerin yorgunluğunu bırak. Sen her halinle değerlisin.'},
    ];
    final batch = db.batch();
    for (final m in messages) {
      batch.insert('motivation_messages', m);
    }
    await batch.commit(noResult: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // JOURNAL ENTRIES — CRUD İşlemleri
  // ═══════════════════════════════════════════════════════════════

  /// Yeni journal entry ekler. Eklenen kaydın [id]'sini döner.
  Future<int> insertEntry(JournalEntry entry) async {
    try {
      final db = await database;
      return await db.insert('journal_entries', entry.toMap());
    } catch (e) {
      debugPrint('❌ Entry ekleme hatası: $e');
      rethrow;
    }
  }

  /// Mevcut bir journal entry'yi günceller.
  Future<int> updateEntry(JournalEntry entry) async {
    try {
      final db = await database;
      final map = entry.toMap();
      map['updated_at'] = DateTime.now().toIso8601String();
      return await db.update(
        'journal_entries',
        map,
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      debugPrint('❌ Entry güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Belirtilen [id]'ye sahip entry'yi siler.
  Future<int> deleteEntry(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'journal_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('❌ Entry silme hatası: $e');
      rethrow;
    }
  }

  /// Tüm entry'leri tarih sırasıyla (en yeniden eskiye) getirir.
  Future<List<JournalEntry>> getEntries() async {
    try {
      final db = await database;
      final maps = await db.query(
        'journal_entries',
        orderBy: 'date DESC',
      );
      return maps.map((map) => JournalEntry.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Entry listeleme hatası: $e');
      return [];
    }
  }

  /// Belirli bir entry'yi [id]'ye göre getirir.
  Future<JournalEntry?> getEntry(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'journal_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return JournalEntry.fromMap(maps.first);
    } catch (e) {
      debugPrint('❌ Entry getirme hatası: $e');
      return null;
    }
  }

  /// [start] ve [end] tarih aralığındaki entry'leri getirir.
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await database;
      final maps = await db.query(
        'journal_entries',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'date DESC',
      );
      return maps.map((map) => JournalEntry.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Tarih aralığı sorgu hatası: $e');
      return [];
    }
  }

  /// Son [days] günün entry'lerini getirir.
  Future<List<JournalEntry>> getRecentEntries(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - days);
    return getEntriesByDateRange(start, now);
  }

  /// [query] metnini trigger veya notlarda arar.
  Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      final db = await database;
      final maps = await db.query(
        'journal_entries',
        where: 'trigger_text LIKE ? OR notes LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'date DESC',
      );
      return maps.map((map) => JournalEntry.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Arama hatası: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // İSTATİSTİK SORGULARI
  // ═══════════════════════════════════════════════════════════════

  /// [start]-[end] aralığındaki ortalama mood skorunu döner.
  Future<double> getAverageMood(DateTime start, DateTime end) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT AVG(mood_score) as avg_mood FROM journal_entries WHERE date >= ? AND date <= ?',
        [start.toIso8601String(), end.toIso8601String()],
      );
      final avg = result.first['avg_mood'];
      if (avg == null) return 0.0;
      return (avg as num).toDouble();
    } catch (e) {
      debugPrint('❌ Ortalama mood sorgu hatası: $e');
      return 0.0;
    }
  }

  /// Son 4 haftanın haftalık ortalamalarını döner.
  Future<List<Map<String, dynamic>>> getWeeklyAverages() async {
    try {
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
    } catch (e) {
      debugPrint('❌ Haftalık ortalama sorgu hatası: $e');
      return [];
    }
  }

  /// Son [days] günün günlük ortalamalarını döner.
  Future<List<Map<String, dynamic>>> getDailyAverages(int days) async {
    try {
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
    } catch (e) {
      debugPrint('❌ Günlük ortalama sorgu hatası: $e');
      return [];
    }
  }

  /// Tarih aralığındaki toplam entry sayısını döner.
  Future<int> _getEntryCount(DateTime start, DateTime end) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM journal_entries WHERE date >= ? AND date <= ?',
        [start.toIso8601String(), end.toIso8601String()],
      );
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('❌ Entry sayısı sorgu hatası: $e');
      return 0;
    }
  }

  /// En sık kullanılan tetikleyicileri döner.
  Future<List<Map<String, dynamic>>> getTopTriggers({int limit = 5}) async {
    try {
      final db = await database;
      final entries = await db.query('journal_entries');

      final Map<String, int> triggerCounts = {};
      for (final entry in entries) {
        final trigger = entry['trigger_text'] as String;
        if (trigger.isNotEmpty) {
          triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
        }
      }

      final sorted = triggerCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(limit)
          .map((e) => {'trigger': e.key, 'count': e.value})
          .toList();
    } catch (e) {
      debugPrint('❌ Top trigger sorgu hatası: $e');
      return [];
    }
  }

  /// Toplam journal entry sayısını döner.
  Future<int> getTotalEntryCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM journal_entries',
      );
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('❌ Toplam entry sayısı sorgu hatası: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // COPING STRATEGIES — CRUD İşlemleri
  // ═══════════════════════════════════════════════════════════════

  /// Tüm coping stratejilerini kullanım sırasıyla döner.
  Future<List<CopingStrategy>> getStrategies() async {
    try {
      final db = await database;
      final maps = await db.query(
        'coping_strategies',
        orderBy: 'usage_count DESC',
      );
      return maps.map((map) => CopingStrategy.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Strateji listeleme hatası: $e');
      return [];
    }
  }

  /// Yeni coping stratejisi ekler. Eklenen kaydın [id]'sini döner.
  Future<int> insertStrategy(CopingStrategy strategy) async {
    try {
      final db = await database;
      return await db.insert('coping_strategies', strategy.toMap());
    } catch (e) {
      debugPrint('❌ Strateji ekleme hatası: $e');
      rethrow;
    }
  }

  /// Belirtilen [id]'ye sahip stratejiyi siler.
  Future<int> deleteStrategy(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'coping_strategies',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('❌ Strateji silme hatası: $e');
      rethrow;
    }
  }

  /// Belirtilen [name] isimli stratejinin kullanım sayısını 1 artırır.
  Future<void> incrementStrategyUsage(String name) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE coping_strategies SET usage_count = usage_count + 1 WHERE name = ?',
        [name],
      );
    } catch (e) {
      debugPrint('❌ Strateji kullanım güncelleme hatası: $e');
    }
  }

  /// En çok kullanılan [limit] kadar stratejiyi döner.
  Future<List<CopingStrategy>> getTopStrategies({int limit = 5}) async {
    try {
      final db = await database;
      final maps = await db.query(
        'coping_strategies',
        where: 'usage_count > 0',
        orderBy: 'usage_count DESC',
        limit: limit,
      );
      return maps.map((map) => CopingStrategy.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Top strateji sorgu hatası: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AI SUGGESTIONS — Sorgular
  // ═══════════════════════════════════════════════════════════════

  /// Belirtilen [category] (Düşük/Orta/Yüksek) için önerileri döner.
  Future<List<AiSuggestion>> getSuggestionsByMood(String category) async {
    try {
      final db = await database;
      final maps = await db.query(
        'ai_suggestions',
        where: 'mood_category = ?',
        whereArgs: [category],
        orderBy: 'priority_level ASC',
      );
      return maps.map((map) => AiSuggestion.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ AI öneri sorgu hatası: $e');
      return [];
    }
  }

  /// Mood skorunu kategoriye çevirip öneriler döner.
  ///
  /// - 1-3: Düşük
  /// - 4-7: Orta
  /// - 8-10: Yüksek
  Future<List<AiSuggestion>> getSuggestionsForScore(int moodScore) async {
    String category;
    if (moodScore <= 3) {
      category = 'Düşük';
    } else if (moodScore <= 7) {
      category = 'Orta';
    } else {
      category = 'Yüksek';
    }
    return getSuggestionsByMood(category);
  }

  /// Tüm AI önerilerini döner.
  Future<List<AiSuggestion>> getAllSuggestions() async {
    try {
      final db = await database;
      final maps = await db.query('ai_suggestions', orderBy: 'mood_category, priority_level');
      return maps.map((map) => AiSuggestion.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Tüm öneriler sorgu hatası: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MOTIVATION MESSAGES — Sorgular
  // ═══════════════════════════════════════════════════════════════

  /// Bugünün gününe ait motivasyon mesajını döner.
  Future<MotivationMessage?> getMotivationForToday() async {
    try {
      const dayNames = [
        'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
        'Cuma', 'Cumartesi', 'Pazar',
      ];
      // DateTime.weekday: 1=Pazartesi ... 7=Pazar
      final todayName = dayNames[DateTime.now().weekday - 1];

      final db = await database;
      final maps = await db.query(
        'motivation_messages',
        where: 'day_of_week = ?',
        whereArgs: [todayName],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return MotivationMessage.fromMap(maps.first);
    } catch (e) {
      debugPrint('❌ Motivasyon mesajı sorgu hatası: $e');
      return null;
    }
  }

  /// Tüm motivasyon mesajlarını döner.
  Future<List<MotivationMessage>> getAllMotivationMessages() async {
    try {
      final db = await database;
      final maps = await db.query('motivation_messages');
      return maps.map((map) => MotivationMessage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Motivasyon mesajları sorgu hatası: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // VERİTABANI YÖNETİMİ
  // ═══════════════════════════════════════════════════════════════

  /// Veritabanı bağlantısını güvenli bir şekilde kapatır.
  Future<void> close() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
      }
    } catch (e) {
      debugPrint('❌ Veritabanı kapatma hatası: $e');
    } finally {
      _database = null;
    }
  }

  /// Veritabanının sağlık kontrolünü yapar.
  ///
  /// Başarılıysa `true`, herhangi bir hata varsa `false` döner.
  Future<bool> healthCheck() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      debugPrint('❌ Veritabanı sağlık kontrolü başarısız: $e');
      return false;
    }
  }
}
