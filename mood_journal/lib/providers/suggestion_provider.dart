import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/ai_suggestion.dart';
import '../models/motivation_message.dart';

/// AI önerileri ve motivasyon mesajları için state yönetimi.
///
/// Kullanıcının mood skoruna göre öneri sunar ve
/// günün motivasyon mesajını yönetir.
class SuggestionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<AiSuggestion> _currentSuggestions = [];
  MotivationMessage? _todayMotivation;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ─── Getters ───
  List<AiSuggestion> get currentSuggestions => _currentSuggestions;
  MotivationMessage? get todayMotivation => _todayMotivation;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Başlangıç verilerini yükler (günün motivasyon mesajı).
  ///
  /// Çift yükleme korumalıdır. [force] ile zorla yeniden yüklenebilir.
  Future<void> initialize({bool force = false}) async {
    if (_isInitialized && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _todayMotivation = await _db.getMotivationForToday();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Öneriler yüklenirken bir sorun oluştu.';
      debugPrint('❌ Suggestion init hatası: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Verilen [moodScore]'a göre AI önerilerini yükler.
  ///
  /// Mood skoru kategoriye çevrilir:
  /// - 1-3: Düşük
  /// - 4-7: Orta
  /// - 8-10: Yüksek
  Future<void> loadSuggestionsForMood(int moodScore) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSuggestions = await _db.getSuggestionsForScore(moodScore);
    } catch (e) {
      debugPrint('❌ Mood önerileri yükleme hatası: $e');
      _currentSuggestions = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tüm AI önerilerini getirir.
  Future<List<AiSuggestion>> getAllSuggestions() async {
    try {
      return await _db.getAllSuggestions();
    } catch (e) {
      debugPrint('❌ Tüm öneriler hatası: $e');
      return [];
    }
  }

  /// Tüm motivasyon mesajlarını getirir.
  Future<List<MotivationMessage>> getAllMotivationMessages() async {
    try {
      return await _db.getAllMotivationMessages();
    } catch (e) {
      debugPrint('❌ Tüm motivasyon mesajları hatası: $e');
      return [];
    }
  }

  /// Mevcut önerileri temizler.
  void clearSuggestions() {
    _currentSuggestions = [];
    notifyListeners();
  }
}
