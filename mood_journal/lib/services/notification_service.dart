import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Bildirim servisini başlat
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Bildirime dokunulduğunda uygulama açılır
    debugPrint('Bildirime dokunuldu: ${response.payload}');
  }

  /// Günlük hatırlatıcı ayarla
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Önce mevcut hatırlatıcıları iptal et
    await cancelAllReminders();

    const androidDetails = AndroidNotificationDetails(
      'mood_journal_daily',
      'Günlük Hatırlatıcı',
      channelDescription: 'Günlük duygu kaydı hatırlatıcısı',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Bugün nasıl hissediyorsun? Duygularını kaydet ve ilerlemenizi takip et. 💙',
        contentTitle: 'Bugün nasılsın? 🌟',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Platform'a göre zamanlama
    // Not: Gerçek uygulamada timezone paketi ile yapılmalı
    // MVP için basit bildirim gösterimi
    await _notifications.periodicallyShow(
      0,
      'Bugün nasılsın? 🌟',
      'Duygularını kaydet ve ilerlemenizi takip et. 💙',
      RepeatInterval.daily,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'daily_reminder',
    );
  }

  /// Test bildirimi gönder
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'mood_journal_test',
      'Test Bildirimi',
      channelDescription: 'Test bildirimi',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'MoodJournal 💙',
      'Bildirimler başarıyla ayarlandı! Artık günlük hatırlatıcılar alacaksınız.',
      notificationDetails,
    );
  }

  /// Tüm hatırlatıcıları iptal et
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  /// İzin iste (Android 13+)
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true; // iOS izinleri init'te isteniyor
  }
}
