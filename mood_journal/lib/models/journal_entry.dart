import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  String? id;
  String userId;
  DateTime date;
  int moodScore;
  String trigger;
  String? notes;
  String? copingStrategy;
  DateTime createdAt;

  JournalEntry({
    this.id,
    this.userId = '',
    required this.date,
    required this.moodScore,
    required this.trigger,
    this.notes,
    this.copingStrategy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Firestore'a yazılacak Map'e dönüştür.
  /// [id] alanı Firestore document ID olarak tutulduğu için map'e eklenmez.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'user_id': userId,
      'date': Timestamp.fromDate(date),
      'mood_score': moodScore,
      'trigger_text': trigger,
      'notes': notes,
      'coping_strategy': copingStrategy,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Firestore DocumentSnapshot'tan oluştur.
  factory JournalEntry.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: doc.id,
      userId: map['user_id'] as String,
      date: (map['date'] as Timestamp).toDate(),
      moodScore: map['mood_score'] as int,
      trigger: map['trigger_text'] as String,
      notes: map['notes'] as String?,
      copingStrategy: map['coping_strategy'] as String?,
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  /// Firestore Map'ten oluştur (geriye uyumluluk için).
  factory JournalEntry.fromMap(Map<String, dynamic> map, {String? docId}) {
    return JournalEntry(
      id: docId ?? map['id'] as String?,
      userId: map['user_id'] as String? ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'] as String),
      moodScore: map['mood_score'] as int,
      trigger: map['trigger_text'] as String,
      notes: map['notes'] as String?,
      copingStrategy: map['coping_strategy'] as String?,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.parse(map['created_at'] as String),
    );
  }

  /// Kopyasını oluştur (düzenleme için)
  JournalEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? moodScore,
    String? trigger,
    String? notes,
    String? copingStrategy,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
    return 'JournalEntry(id: $id, userId: $userId, date: $formattedDate, mood: $moodScore, trigger: $trigger)';
  }
}
