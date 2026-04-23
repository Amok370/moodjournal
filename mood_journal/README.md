# MoodJournal - Duygusal Sağlık Takip Uygulaması 📱

Psikiyatrik rahatsızlıkları olan (anksiyete, depresyon, OKB vb.) bireylerin günlük duygu durumlarını takip etmesi, tetikleyicilerini anlaması, grafiklerle ilerleme görmesi ve terapistine PDF rapor sunabilmesi için Flutter tabanlı mobil uygulama.

## Özellikler ✨

- **Günlük Duygu Kaydı**: 1-10 skalasında emoji tabanlı duygu takibi
- **Tetikleyici Takibi**: Hangi olayların duygularınızı etkilediğini kaydedin
- **Coping Stratejileri**: 10+ hazır başa çıkma yöntemi + kendi stratejinizi ekleyin
- **İstatistikler & Grafikler**: Haftalık/aylık trend grafikleri, en sık tetikleyiciler
- **PDF Rapor**: Terapistinize sunmak üzere detaylı rapor oluşturun
- **Hatırlatıcılar**: Günlük bildirimlerle kayıt tutmayı unutmayın
- **Koyu/Açık Tema**: Göz yormayan tasarım seçenekleri

## Teknik Stack ⚙️

| Teknoloji | Görev |
|-----------|-------|
| Flutter 3.x | Mobil UI Framework |
| Provider | State Management |
| sqflite | SQLite Veritabanı |
| fl_chart | Grafikler |
| pdf + printing | PDF Rapor |
| flutter_local_notifications | Bildirimler |
| google_fonts | Tipografi |

## Kurulum 🚀

### Ön Gereksinimler
- Flutter SDK 3.10+
- Dart SDK 3.0+
- Android Studio / VS Code
- Android SDK (Android için)
- Xcode (iOS için, sadece macOS)

### Adımlar

```bash
# 1. Proje dizinine gidin
cd mood_journal

# 2. Bağımlılıkları yükleyin
flutter pub get

# 3. Uygulamayı çalıştırın
flutter run
```

## Proje Yapısı 📁

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── app_theme.dart               # Tema ve renk sistemi
├── models/                      # Veri modelleri
│   ├── journal_entry.dart
│   └── coping_strategy.dart
├── database/                    # SQLite veritabanı
│   └── database_helper.dart
├── providers/                   # State management
│   ├── journal_provider.dart
│   └── coping_provider.dart
├── screens/                     # Ekranlar
│   ├── home_screen.dart
│   ├── add_entry_screen.dart
│   ├── edit_entry_screen.dart
│   ├── history_screen.dart
│   ├── analytics_screen.dart
│   ├── coping_screen.dart
│   ├── settings_screen.dart
│   └── entry_detail_screen.dart
├── widgets/                     # UI bileşenleri
│   ├── mood_slider.dart
│   ├── entry_card.dart
│   ├── mood_chart.dart
│   ├── trigger_bar_chart.dart
│   ├── stat_card.dart
│   └── coping_tile.dart
└── services/                    # Servisler
    ├── pdf_service.dart
    └── notification_service.dart
```

## Hedef Kitle 🎯

- Anksiyete Bozukluğu
- Depresyon
- OKB (Obsesif Kompulsif Bozukluk)
- PTSD
- Bipolar Bozukluk

## Lisans 📄

Bu proje eğitim amaçlıdır.
