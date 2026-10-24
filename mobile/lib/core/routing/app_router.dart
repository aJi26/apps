import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/daily_checkin/daily_checkin_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_setup_screen.dart';
import '../../features/auth/personality_quiz_screen.dart';

enum GateResult { routed, retry }

class AppRouter {
  static Future<GateResult> resolve(BuildContext context) async {
    try {
      final userResponse = await ApiService.request('GET', 'user');
      if (userResponse.statusCode == 401 || userResponse.statusCode == 403) {
        await ApiService.logout();
        if (context.mounted) _replace(context, const OnboardingScreen());
        return GateResult.routed;
      }
      if (userResponse.statusCode != 200) return GateResult.retry;

      final user = ApiService.decode(userResponse);
      final profile = user['profile'];
      if (profile == null || profile['birthday'] == null) {
        if (context.mounted) _replace(context, const ProfileSetupScreen());
        return GateResult.routed;
      }

      final quizResponse = await ApiService.request('GET', 'quiz/result');
      if (quizResponse.statusCode != 200) return GateResult.retry;
      if (ApiService.decode(quizResponse)['completed'] != true) {
        if (context.mounted) _replace(context, const PersonalityQuizScreen());
        return GateResult.routed;
      }

      final potretResponse = await ApiService.request('GET', 'potret/status');
      if (potretResponse.statusCode != 200) return GateResult.retry;
      final done = ApiService.decode(potretResponse)['completed'] == true;
      if (context.mounted) {
        _replace(
          context,
          done ? const HomeScreen() : const DailyCheckinScreen(),
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
