import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/routing/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Jalankan perizinan di latar belakang tanpa menahan frame
    NotificationService.requestPermissionOnFirstLaunch();

    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final token = await ApiService.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      _navigateToOnboarding();
      return;
    }

    final result = await AppRouter.resolve(context);
    if (result == GateResult.retry && mounted) {
      setState(
        () => error =
            'We couldn’t reach your space. Check your connection and try again.',
      );
    } else if (mounted) {
      // Jika berhasil resolve/login, pindah ke HomeScreen dengan animasi mulus
      _navigateToHome();
    }
  }

  // Animasi Transisi Mulus ke HomeScreen (Pengguna Sudah Login)
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // Animasi Transisi Mulus ke Onboarding (Pengguna Baru)
  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => error = null);
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'lib/assets/image/splash.svg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            placeholderBuilder: (context) => Container(
              color: AppTheme.background,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Her Space',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: const Color(0xFF332726),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.7),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A little space, just for you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5D4037),
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 70,
            right: 70,
            bottom: 75,
            child: Column(
              children: [
                if (error == null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white38,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8B0000),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}