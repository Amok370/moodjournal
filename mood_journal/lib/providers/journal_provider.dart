import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/journal_entry.dart';

class JournalProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<JournalEntry> _entries = [];
  List<JournalEntry> _filteredEntries = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Getters
  List<JournalEntry> get entries => _searchQuery.isEmpty ? _entries : _filteredEntries;
  List<JournalEntry> get allEntries => _entries;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // ─── Entry'leri Yükle ───
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _db.getEntries();
    } catch (e) {
      debugPrint('Entry yükleme hatası: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Yeni Entry Ekle ───
  Future<void> addEntry(JournalEntry entry) async {
    try {
      final id = await _db.insertEntry(entry);
      entry.id = id;

      // Coping stratejisi kullanıldıysa sayacını artır
      if (entry.copingStrategy != null && entry.copingStrategy!.isNotEmpty) {
        await _db.incrementStrategyUsage(entry.copingStrategy!);
      }

      _entries.insert(0, entry); // En başa ekle
      notifyListeners();
    } catch (e) {
      debugPrint('Entry ekleme hatası: $e');
      rethrow;
    }
  }

  // ─── Entry Güncelle ───
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      await _db.updateEntry(entry);
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Entry güncelleme hatası: $e');
      rethrow;
    }
  }

  // ─── Entry Sil ───
  Future<void> deleteEntry(int id) async {
    try {
      await _db.deleteEntry(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Entry silme hatası: $e');
      rethrow;
    }
  }

  // ─── Arama ───
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredEntries = [];
    } else {
      _filteredEntries = await _db.searchEntries(query);
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredEntries = [];
    notifyListeners();
  }

  // ─── Son N Günün Entry'leri ───
  List<JournalEntry> getRecentEntries(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _entries.where((e) => e.date.isAfter(cutoff)).toList();
  }

  // ─── Bugünün Entry'si Var Mı? ───
  bool get hasTodayEntry {
    final now = DateTime.now();
    return _entries.any((e) =>
        e.date.year == now.year &&
        e.date.month == now.month &&
        e.date.day == now.day);
  }

  // ─── Bugünün Entry'leri ───
  List<JournalEntry> get todayEntries {
    final now = DateTime.now();
    return _entries
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .toList();
  }

  // ═══════════════════════════════════════════
  // İSTATİSTİK FONKSİYONLARI
  // ═══════════════════════════════════════════

  /// Bu ayın ortalama mood skoru
  Future<double> getMonthlyAverage() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return await _db.getAverageMood(start, now);
  }

  /// Haftalık ortalamalar (son 4 hafta)
  Future<List<Map<String, dynamic>>> getWeeklyAverages() async {
    return await _db.getWeeklyAverages();
  }

  /// Günlük ortalamalar (son N gün)
  Future<List<Map<String, dynamic>>> getDailyAverages(int days) async {
    return await _db.getDailyAverages(days);
  }

  /// En sık tetikleyiciler
  Future<List<Map<String, dynamic>>> getTopTriggers({int limit = 5}) async {
    return await _db.getTopTriggers(limit: limit);
  }

  /// Toplam entry sayısı
  Future<int> getTotalCount() async {
    return await _db.getTotalEntryCount();
  }

  /// Tarih aralığına göre entry'ler (PDF rapor için)
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _db.getEntriesByDateRange(start, end);
  }

  /// Streak hesapla (üst üste kaç gün kayıt yapılmış)
  int get currentStreak {
    if (_entries.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 365; i++) {
      final hasEntry = _entries.any((e) =>
          e.date.year == checkDate.year &&
          e.date.month == checkDate.month &&
          e.date.day == checkDate.day);

      if (hasEntry) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}
