import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 1. TAMBAHKAN IMPORT INI

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';

// Fungsi ini WAJIB di luar class (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Ambil data dari Laravel lalu munculkan pakai Notifikasi Lokal
  if (message.data.isNotEmpty) {
    await NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.data['title'] ?? '',
      body: message.data['body'] ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Daftarkan handler background FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await NotificationService.init();
  await NotificationService.requestPermissionOnFirstLaunch();
  
  await AppTheme.initTheme();
  // 2. DISESUAIKAN MENJADI HerSpaceApp (sebelumnya MyApp)
  runApp(const HerSpaceApp());
}

class HerSpaceApp extends StatelessWidget {
  const HerSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeKey>(
      valueListenable: AppTheme.currentThemeNotifier,
      builder: (context, themeKey, _) {
        return MaterialApp(
          title: 'Her Space',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          home: const SplashScreen(),
        );
      },
    );
  }
}