import 'package:flutter/material.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.initTheme(); // Load tema tersimpan
  await NotificationService.init();
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