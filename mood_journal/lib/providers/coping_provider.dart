import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/coping_strategy.dart';

/// Coping stratejilerinin state yönetimini sağlayan provider.
///
/// Varsayılan ve kullanıcı tanımlı stratejileri yönetir.
/// Kullanım sayaçlarını takip eder.
class CopingProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<CopingStrategy> _strategies = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ─── Getters ───
  List<CopingStrategy> get strategies => _strategies;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Son hata mesajı. Hata yoksa `null` döner.
  String? get errorMessage => _errorMessage;

  /// Hata durumunu temizler.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Varsayılan stratejiler
  List<CopingStrategy> get defaultStrategies =>
      _strategies.where((s) => s.isDefault).toList();

  /// Kullanıcı eklenen stratejiler
  List<CopingStrategy> get userStrategies =>
      _strategies.where((s) => !s.isDefault).toList();

  /// Kullanılmış stratejiler (sayaç > 0)
  List<CopingStrategy> get usedStrategies =>
      _strategies.where((s) => s.usageCount > 0).toList();

  // ─── Stratejileri Yükle ───
  /// Veritabanından tüm stratejileri yükler.
  ///
  /// Çift yükleme koruması: [_isInitialized] true ise tekrar sorgu yapmaz.
  /// Zorla yeniden yüklemek için [force] = `true` kullanın.
  Future<void> loadStrategies({bool force = false}) async {
    if (_isInitialized && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _strategies = await _db.getStrategies();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Stratejiler yüklenirken bir sorun oluştu.';
      debugPrint('❌ Strateji yükleme hatası: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Yeni Strateji Ekle ───
  Future<void> addStrategy(CopingStrategy strategy) async {
    try {
      final id = await _db.insertStrategy(strategy);
      strategy.id = id;
      _strategies.add(strategy);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Strateji ekleme hatası: $e');
      rethrow;
    }
  }

  // ─── Strateji Sil ───
  Future<void> deleteStrategy(int id) async {
    try {
      await _db.deleteStrategy(id);
      _strategies.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Strateji silme hatası: $e');
      rethrow;
    }
  }

  // ─── Kullanım Sayısını Artır ───
  Future<void> incrementUsage(String name) async {
    try {
      await _db.incrementStrategyUsage(name);
      final index = _strategies.indexWhere((s) => s.name == name);
      if (index != -1) {
        _strategies[index] = _strategies[index].copyWith(
          usageCount: _strategies[index].usageCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Kullanım artırma hatası: $e');
    }
  }

  /// En çok kullanılan stratejiler
  Future<List<CopingStrategy>> getTopStrategies({int limit = 5}) async {
    return await _db.getTopStrategies(limit: limit);
  }

  /// Strateji adlarını listele (entry formunda seçim için)
  List<String> get strategyNames => _strategies.map((s) => s.name).toList();
}
