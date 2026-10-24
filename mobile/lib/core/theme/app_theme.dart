import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeKey { sage, pink, lavender, sunset, mocha }

class AppThemeData {
  final String name;
  final Color primary;
  final Color background;
  final Color sageSoft;
  final Color textPrimary;
  final Color textMuted;
  final Color card;
  final Color border;

  const AppThemeData({
    required this.name,
    required this.primary,
    required this.background,
    required this.sageSoft,
    this.textPrimary = const Color(0xFF2D312E),
    this.textMuted = const Color(0xFF8C938E),
    this.card = Colors.white,
    this.border = const Color(0xFFE8E7E2),
  });
}

class AppTheme {
  // Preset warna tema
  static const Map<AppThemeKey, AppThemeData> presets = {
    AppThemeKey.sage: AppThemeData(
      name: 'Sage Green',
      primary: Color(0xFF4A6B53),
      background: Color(0xFFF9F8F6),
      sageSoft: Color(0xFFEAF0EB),
    ),
    AppThemeKey.pink: AppThemeData(
      name: 'Pink Blossom',
      primary: Color(0xFFD87093),
      background: Color(0xFFFFF5F7),
      sageSoft: Color(0xFFFAD2E1),
    ),
    AppThemeKey.lavender: AppThemeData(
      name: 'Lavender Dream',
      primary: Color(0xFF7E57C2),
      background: Color(0xFFF8F5FF),
      sageSoft: Color(0xFFEDE7F6),
    ),
    AppThemeKey.sunset: AppThemeData(
      name: 'Warm Sunset',
      primary: Color(0xFFD96B43),
      background: Color(0xFFFFF8F5),
      sageSoft: Color(0xFFFFE0B2),
    ),
    AppThemeKey.mocha: AppThemeData(
      name: 'Mocha Cream',
      primary: Color(0xFF8E6B58),
      background: Color(0xFFFAF7F2),
      sageSoft: Color(0xFFF7ECE1),
    ),
  };

  static final ValueNotifier<AppThemeKey> currentThemeNotifier =
      ValueNotifier<AppThemeKey>(AppThemeKey.sage);

  static AppThemeData get current =>
      presets[currentThemeNotifier.value] ?? presets[AppThemeKey.sage]!;

  // Tetap sediakan static const default agar widget 'const' tidak error sama sekali
  static const Color primary = Color(0xFF4A6B53);
  static const Color background = Color(0xFFF9F8F6);
  static const Color sageSoft = Color(0xFFEAF0EB);
  static const Color textPrimary = Color(0xFF2D312E);
  static const Color textMuted = Color(0xFF8C938E);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE8E7E2);
  static const Color blush = Color(0xFFF5E7E3);
  static const Color gold = Color(0xFFE8C981);

  static Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final keyIndex = prefs.getInt('app_theme_key') ?? 0;
    if (keyIndex >= 0 && keyIndex < AppThemeKey.values.length) {
      currentThemeNotifier.value = AppThemeKey.values[keyIndex];
    }
  }

  static Future<void> setTheme(AppThemeKey key) async {
    currentThemeNotifier.value = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme_key', key.index);
  }

  static ThemeData get themeData {
    final active = current;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: active.primary,
        surface: active.background,
        primary: active.primary,
        secondary: active.sageSoft,
      ),
    );
    final poppins = base.textTheme.apply(
      fontFamily: GoogleFonts.poppins().fontFamily,
    );
    final textTheme = poppins.copyWith(
      displayLarge: GoogleFonts.kalam(
        fontSize: 57,
        color: active.textPrimary,
      ),
      displayMedium: GoogleFonts.kalam(
        fontSize: 45,
        color: active.textPrimary,
      ),
      displaySmall: GoogleFonts.kalam(
        fontSize: 36,
        color: active.textPrimary,
      ),
      headlineLarge: GoogleFonts.kalam(
        fontSize: 32,
        color: active.textPrimary,
      ),
      headlineMedium: GoogleFonts.kalam(
        fontSize: 28,
        color: active.textPrimary,
      ),
      headlineSmall: GoogleFonts.kalam(
        fontSize: 24,
        color: active.textPrimary,
      ),
      titleLarge: GoogleFonts.kalam(fontSize: 20, color: active.textPrimary),
    );

    return base.copyWith(
      scaffoldBackgroundColor: active.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: active.background,
        foregroundColor: active.textPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.kalam(
          fontSize: 25,
          color: active.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: active.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: active.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: active.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: active.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: active.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: active.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: active.textPrimary,
          minimumSize: const Size(0, 54),
          side: BorderSide(color: active.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}