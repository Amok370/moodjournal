/// MySQL dump'taki `motivation_messages` tablosunun Flutter karşılığı.
///
/// Haftanın her günü için kullanıcıya gösterilen motivasyon mesajları.
class MotivationMessage {
  final int? id;
  final String dayOfWeek;
  final String messageText;
  final String? createdAt;

  const MotivationMessage({
    this.id,
    required this.dayOfWeek,
    required this.messageText,
    this.createdAt,
  });

  /// SQLite Map'e dönüştür.
  /// [id] null ise map'ten çıkarılır (AUTOINCREMENT uyumu).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'day_of_week': dayOfWeek,
      'message_text': messageText,
    };
    if (id != null) {
      map['id'] = id;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt;
    }
    return map;
  }

  /// SQLite Map'ten model oluştur.
  factory MotivationMessage.fromMap(Map<String, dynamic> map) {
    return MotivationMessage(
      id: map['id'] as int?,
      dayOfWeek: map['day_of_week'] as String,
      messageText: map['message_text'] as String,
      createdAt: map['created_at'] as String?,
    );
  }

  /// Kopyasını oluştur.
  MotivationMessage copyWith({
    int? id,
    String? dayOfWeek,
    String? messageText,
    String? createdAt,
  }) {
    return MotivationMessage(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MotivationMessage(id: $id, day: $dayOfWeek)';
  }
}
