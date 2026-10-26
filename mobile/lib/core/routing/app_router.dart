import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/personality_quiz_screen.dart';
import '../../features/daily_checkin/daily_checkin_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_setup_screen.dart';

enum GateResult { routed, retry }

class AppRouter {
  static Future<GateResult> resolve(BuildContext context) async {
    try {
      // 1. Cek Sesi User & Authentikasi
      final userResponse = await ApiService.request('GET', 'user');
      if (userResponse.statusCode == 401 || userResponse.statusCode == 403) {
        await ApiService.logout();
        if (context.mounted) _replace(context, const OnboardingScreen());
        return GateResult.routed;
      }
      if (userResponse.statusCode != 200) return GateResult.retry;

      final user = ApiService.decode(userResponse);
      final profile = user['profile'];

      // 2. Cek Kelengkapan Profil (Tanggal Lahir)
      if (profile == null || profile['birthday'] == null) {
        if (context.mounted) _replace(context, const ProfileSetupScreen());
        return GateResult.routed;
      }

      // 3. Cek Status Kuis MBTI (Onboarding 1x)
      final quizResponse = await ApiService.request('GET', 'quiz/result');
      if (quizResponse.statusCode != 200) return GateResult.retry;
      
      final quizData = ApiService.decode(quizResponse);
      if (quizData['completed'] != true) {
        if (context.mounted) _replace(context, const PersonalityQuizScreen());
        return GateResult.routed;
      }

      // 4. Cek Check-in Foto Potret Hari Ini -> Ke Home atau Daily Check-in
      final potretResponse = await ApiService.request('GET', 'potret/status');
      if (potretResponse.statusCode != 200) return GateResult.retry;
      
      final donePotret = ApiService.decode(potretResponse)['completed'] == true;
      if (context.mounted) {
        _replace(
          context,
          donePotret ? const HomeScreen() : const DailyCheckinScreen(),
        );
      }
      return GateResult.routed;
    } catch (_) {
      return GateResult.retry;
    }
  }

  static void _replace(BuildContext context, Widget page) =>
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => page),
        (_) => false,
      );
}