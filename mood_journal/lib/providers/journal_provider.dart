import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

/// Journal entry'lerinin state yönetimini sağlayan provider.
///
/// Firestore üzerinden CRUD operasyonları, arama ve
/// istatistik hesaplama işlevlerini UI katmanına sunar.
/// Tüm async operasyonlar try-catch ile korunmuştur.
class JournalProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<JournalEntry> _entries = [];
  List<JournalEntry> _filteredEntries = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String _searchQuery = '';
  String? _errorMessage;

  // ─── Helpers ───

  /// Mevcut kullanıcının UID'sini döner. Giriş yapılmamışsa hata fırlatır.
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu bulunamadı.');
    return user.uid;
  }

  /// Mevcut kullanıcının journal_entries alt koleksiyonuna referans.
  CollectionReference<Map<String, dynamic>> get _entriesRef =>
      _firestore.collection('users').doc(_uid).collection('journal_entries');

  // ─── Getters ───
  List<JournalEntry> get entries =>
      _searchQuery.isEmpty ? _entries : _filteredEntries;
  List<JournalEntry> get allEntries => _entries;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get searchQuery => _searchQuery;

  /// Son hata mesajı. Hata yoksa `null` döner.
  String? get errorMessage => _errorMessage;

  /// Hata durumunu temizler.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Entry'leri Yükle ───
  /// Firestore'dan mevcut kullanıcının tüm entry'lerini yükler.
  ///
  /// Çift yükleme koruması vardır: [_isInitialized] kontrolü sayesinde
  /// birden fazla kez çağrılsa bile yalnızca ilkinde sorgu yapar.
  /// Zorla yeniden yüklemek için [force] parametresini `true` yapın.
  Future<void> loadEntries({bool force = false}) async {
    if (_isInitialized && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _entriesRef
          .orderBy('date', descending: true)
          .get();

      _entries = snapshot.docs
          .map((doc) => JournalEntry.fromDocument(doc))
          .toList();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Veriler yüklenirken bir sorun oluştu.';
      debugPrint('❌ Entry yükleme hatası: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Yeni Entry Ekle ───
  Future<void> addEntry(JournalEntry entry) async {
    try {
      // userId'yi mevcut kullanıcıyla eşleştir
      final entryWithUser = entry.copyWith(userId: _uid);
      final docRef = await _entriesRef.add(entryWithUser.toMap());
      entryWithUser.id = docRef.id;

      _entries.insert(0, entryWithUser); // En başa ekle
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Entry ekleme hatası: $e');
      rethrow;
    }
  }

  // ─── Entry Güncelle ───
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      if (entry.id == null) throw Exception('Entry ID bulunamadı.');

      final data = entry.toMap();
      data['updated_at'] = Timestamp.now();
      await _entriesRef.doc(entry.id).update(data);

      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Entry güncelleme hatası: $e');
      rethrow;
    }
  }

  // ─── Entry Sil ───
  Future<void> deleteEntry(String id) async {
    try {
      await _entriesRef.doc(id).delete();
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Entry silme hatası: $e');
      rethrow;
    }
  }

  // ─── Arama ───
  /// Client-side arama. Firestore tam metin araması desteklemediği için
  /// yüklü entry'ler üzerinden filtreleme yapar.
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredEntries = [];
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredEntries = _entries.where((e) {
        final triggerMatch = e.trigger.toLowerCase().contains(lowerQuery);
        final notesMatch =
            e.notes?.toLowerCase().contains(lowerQuery) ?? false;
        return triggerMatch || notesMatch;
      }).toList();
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

  // ═══════════════════════════════════════════════════════════════
  // İSTATİSTİK FONKSİYONLARI
  // ═══════════════════════════════════════════════════════════════

  /// Bu ayın ortalama mood skoru
  Future<double> getMonthlyAverage() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final monthEntries = _entries.where((e) =>
        e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        e.date.isBefore(now.add(const Duration(days: 1))));
    if (monthEntries.isEmpty) return 0.0;
    final sum = monthEntries.fold<int>(0, (s, e) => s + e.moodScore);
    return sum / monthEntries.length;
  }

  /// Haftalık ortalamalar (son 4 hafta)
  Future<List<Map<String, dynamic>>> getWeeklyAverages() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> weeklyData = [];

    for (int i = 3; i >= 0; i--) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 7));

      final weekEntries = _entries.where((e) =>
          e.date.isAfter(weekStart) && e.date.isBefore(weekEnd));

      double avg = 0.0;
      if (weekEntries.isNotEmpty) {
        final sum = weekEntries.fold<int>(0, (s, e) => s + e.moodScore);
        avg = sum / weekEntries.length;
      }

      weeklyData.add({
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'average': avg,
        'count': weekEntries.length,
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

      final dayEntries = _entries.where((e) =>
          e.date.isAfter(day.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(dayEnd));

      double avg = 0.0;
      if (dayEntries.isNotEmpty) {
        final sum = dayEntries.fold<int>(0, (s, e) => s + e.moodScore);
        avg = sum / dayEntries.length;
      }

      dailyData.add({
        'date': day,
        'average': avg,
        'count': dayEntries.length,
      });
    }
    return dailyData;
  }

  /// En sık tetikleyiciler
  Future<List<Map<String, dynamic>>> getTopTriggers({int limit = 5}) async {
    final Map<String, int> triggerCounts = {};
    for (final entry in _entries) {
      if (entry.trigger.isNotEmpty) {
        triggerCounts[entry.trigger] =
            (triggerCounts[entry.trigger] ?? 0) + 1;
      }
    }

    final sorted = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(limit)
        .map((e) => {'trigger': e.key, 'count': e.value})
        .toList();
  }

  /// Toplam entry sayısı
  Future<int> getTotalCount() async {
    return _entries.length;
  }

  /// Tarih aralığına göre entry'ler (PDF rapor için)
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _entries.where((e) =>
        e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        e.date.isBefore(end.add(const Duration(days: 1)))).toList();
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

  /// Kullanıcı çıkış yaptığında state'i sıfırlar.
  void reset() {
    _entries = [];
    _filteredEntries = [];
    _isInitialized = false;
    _isLoading = false;
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }
}
