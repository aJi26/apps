// lib/core/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // 1. DAFTARKAN CHANNEL 'v5' SECARA EKSPLISIT KE OS ANDROID
    const androidChannel = AndroidNotificationChannel(
      'her_space_channel_v5',
      'Her Space Notifications',
      description: 'Channel notifikasi Her Space dengan nada kustom',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('herspace'),
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
    }

    // 2. Ambil Token FCM (Debugging)
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint("=============================================");
      debugPrint("TOKEN FCM HP SAYA:\n$fcmToken");
      debugPrint("=============================================");
    } catch (e) {
      debugPrint("Gagal mengambil FCM Token: $e");
    }

    // 3. Tangkap Notifikasi saat Aplikasi Sedang Terbuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        showNotification(
          id: notification.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      }
    });
  }

  static Future<void> requestPermissionOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRequested = prefs.getBool('has_requested_permissions') ?? false;

    if (!hasRequested) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await prefs.setBool('has_requested_permissions', true);
    }
  }

  /// METHOD BARU: Mengirimkan Token FCM ke Backend Laravel
  static Future<void> syncFcmTokenWithBackend() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        final response = await ApiService.request('POST', 'user/fcm-token', body: {
          'fcm_token': fcmToken,
        });

        if (response.statusCode < 300) {
          debugPrint("FCM Token berhasil disinkronkan ke backend!");
        } else {
          debugPrint("Gagal simpan FCM Token: ${response.statusCode}");
        }
      }
    } catch (e) {
      debugPrint("Error sync FCM Token: $e");
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'her_space_channel_v6',
      'Her Space Notifications',
      channelDescription: 'Channel notifikasi Her Space dengan nada kustom',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('herspace'), 
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        sound: 'herspace.wav', 
      ),
    );

    await _notifications.show(id, title, body, details);
  }
}