// lib/core/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  // Dipanggil saat pertama kali aplikasi diinstall / dibuka
  static Future<void> requestPermissionOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRequested = prefs.getBool('has_requested_permissions') ?? false;

    if (!hasRequested) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Tampilkan pop-up dialog perizinan bawaan HP
      await androidImplementation?.requestNotificationsPermission();

      // Tandai bahwa perizinan awal sudah pernah ditanyakan
      await prefs.setBool('has_requested_permissions', true);
    }
  }

  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'her_space_channel',
      'Her Space Notifications',
      channelDescription: 'Notification channel for Her Space',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      0,
      'Her Space 🌷',
      'Halo! Notifikasi uji coba kamu berhasil muncul nih.',
      details,
    );
  }
}