/// MySQL dump'taki `ai_suggestions` tablosunun Flutter karşılığı.
///
/// Kullanıcının mevcut ruh haline (Düşük / Orta / Yüksek) göre
/// anlamlı öneriler sunan yapay zeka öneri modeli.
class AiSuggestion {
  final int? id;
  final String moodCategory;
  final String suggestionText;
  final int priorityLevel;

  const AiSuggestion({
    this.id,
    required this.moodCategory,
    required this.suggestionText,
    this.priorityLevel = 1,
  });

  /// SQLite Map'e dönüştür.
  /// [id] null ise map'ten çıkarılır (AUTOINCREMENT uyumu).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'mood_category': moodCategory,
      'suggestion_text': suggestionText,
      'priority_level': priorityLevel,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// SQLite Map'ten model oluştur.
  factory AiSuggestion.fromMap(Map<String, dynamic> map) {
    return AiSuggestion(
      id: map['id'] as int?,
      moodCategory: map['mood_category'] as String,
      suggestionText: map['suggestion_text'] as String,
      priorityLevel: map['priority_level'] as int? ?? 1,
    );
  }

  /// Kopyasını oluştur.
  AiSuggestion copyWith({
    int? id,
    String? moodCategory,
    String? suggestionText,
    int? priorityLevel,
  }) {
    return AiSuggestion(
      id: id ?? this.id,
      moodCategory: moodCategory ?? this.moodCategory,
      suggestionText: suggestionText ?? this.suggestionText,
      priorityLevel: priorityLevel ?? this.priorityLevel,
    );
  }

  @override
  String toString() {
    return 'AiSuggestion(id: $id, category: $moodCategory, priority: $priorityLevel)';
  }
}
