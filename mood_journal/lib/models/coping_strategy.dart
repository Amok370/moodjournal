class CopingStrategy {
  int? id;
  String name;
  String? description;
  int usageCount;
  bool isDefault;

  CopingStrategy({
    this.id,
    required this.name,
    this.description,
    this.usageCount = 0,
    this.isDefault = false,
  });

  /// SQLite Map'e dönüştür.
  /// [id] null ise map'ten çıkarılır (AUTOINCREMENT uyumu).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'usage_count': usageCount,
      'is_default': isDefault ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// SQLite Map'ten oluştur
  factory CopingStrategy.fromMap(Map<String, dynamic> map) {
    return CopingStrategy(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      usageCount: map['usage_count'] as int? ?? 0,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }

  CopingStrategy copyWith({
    int? id,
    String? name,
    String? description,
    int? usageCount,
    bool? isDefault,
  }) {
    return CopingStrategy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      usageCount: usageCount ?? this.usageCount,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Varsayılan coping stratejileri
  static List<CopingStrategy> get defaultStrategies => [
        CopingStrategy(
          name: 'Derin Nefes Alma',
          description: '4-7-8 tekniği: 4 sn nefes al, 7 sn tut, 8 sn ver',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Yürüyüş Yapma',
          description: '15-30 dakika açık havada yürüyüş',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Müzik Dinleme',
          description: 'Rahatlatıcı veya sevdiğin müzikleri dinle',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Meditasyon / Yoga',
          description: '10-15 dakika farkındalık meditasyonu',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Sevdiğini Ara',
          description: 'Güvendiğin bir kişiyle konuş',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Günlük Yazma',
          description: 'Hislerini kağıda dök',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Fiziksel Egzersiz',
          description: 'Spor, koşu veya dans',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Rahatlatıcı Aktivite',
          description: 'Banyo, kitap okuma, boyama gibi sakinleştirici bir şey yap',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Grounding Tekniği',
          description: '5 şey gör, 4 şey dokun, 3 şey duy, 2 şey kokla, 1 şey tat',
          isDefault: true,
        ),
        CopingStrategy(
          name: 'Profesyonel Destek',
          description: 'Terapistini veya doktorunu ara',
          isDefault: true,
        ),
      ];

  @override
  String toString() {
    return 'CopingStrategy(id: $id, name: $name, usage: $usageCount)';
  }
}
