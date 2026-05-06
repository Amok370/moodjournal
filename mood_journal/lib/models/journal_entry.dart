class JournalEntry {
  int? id;
  DateTime date;
  int moodScore;
  String trigger;
  String? notes;
  String? copingStrategy;
  DateTime createdAt;

  JournalEntry({
    this.id,
    required this.date,
    required this.moodScore,
    required this.trigger,
    this.notes,
    this.copingStrategy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// SQLite Map'e dönüştür.
  /// [id] null ise map'ten çıkarılır (AUTOINCREMENT uyumu).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date.toIso8601String(),
      'mood_score': moodScore,
      'trigger_text': trigger,
      'notes': notes,
      'coping_strategy': copingStrategy,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// SQLite Map'ten oluştur
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      moodScore: map['mood_score'] as int,
      trigger: map['trigger_text'] as String,
      notes: map['notes'] as String?,
      copingStrategy: map['coping_strategy'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Kopyasını oluştur (düzenleme için)
  JournalEntry copyWith({
    int? id,
    DateTime? date,
    int? moodScore,
    String? trigger,
    String? notes,
    String? copingStrategy,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      moodScore: moodScore ?? this.moodScore,
      trigger: trigger ?? this.trigger,
      notes: notes ?? this.notes,
      copingStrategy: copingStrategy ?? this.copingStrategy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Tarih formatı: "15 Mart 2024"
  String get formattedDate {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  /// Saat formatı: "14:30"
  String get formattedTime {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, date: $formattedDate, mood: $moodScore, trigger: $trigger)';
  }
}
