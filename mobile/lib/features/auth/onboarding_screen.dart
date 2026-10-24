import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import 'login_screen.dart';

// Widget Mikro-Interaksi Tombol
class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const ScaleButton({super.key, required this.child, required this.onTap});

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pager = PageController();
  final ValueNotifier<int> _pageNotifier = ValueNotifier<int>(0);

  static const List<(String, String, String)> _pages = [
    (
      'A little space\njust for you',
      'A gentle place to check in, reflect, and make room for what matters.',
      'lib/assets/image/onboarding1.svg',
    ),
    (
      'Make space for\nyour feelings',
      'Notice how you feel each day, without judgment or pressure.',
      'lib/assets/image/onboarding2.svg',
    ),
    (
      'Grow at your\nown pace',
      'Keep your notes, little goals, and wishes close as you find your way.',
      'lib/assets/image/onboarding3.svg',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache SVG agar transisi tidak patah-patah
    for (final page in _pages) {
      final loader = SvgAssetLoader(page.$3);
      svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  void _next() {
    final currentPage = _pageNotifier.value;
    if (currentPage < _pages.length - 1) {
      _pager.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.05, 0.0),
            end: Offset.zero,
          ).animate(fadeAnimation);

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.current.primary;
    final backgroundColor = AppTheme.current.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 14, 26, 20),
          child: Column(
            children: [
              // 1. Tombol Skip / Continue Atas
              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<int>(
                  valueListenable: _pageNotifier,
                  builder: (context, page, _) {
                    return ScaleButton(
                      onTap: _next,
                      child: TextButton(
                        onPressed: _next,
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                        ),
                        child: Text(
                          page == 2 ? 'Start' : 'Skip',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. PageView Utama
              Expanded(
                child: PageView.builder(
                  controller: _pager,
                  itemCount: _pages.length,
                  onPageChanged: (value) => _pageNotifier.value = value,
                  itemBuilder: (_, index) {
                    final item = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SvgPicture.asset(
                            item.$3,
                            fit: BoxFit.contain,
                            semanticsLabel:
                                'Her Space onboarding illustration ${index + 1}',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item.$1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppTheme.textMuted, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),

              // 3. Dots Indicator Animasi
              ValueListenableBuilder<int>(
                valueListenable: _pageNotifier,
                builder: (context, page, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.all(4),
                        width: page == i ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: page == i ? primaryColor : AppTheme.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              // 4. Tombol Utama Bawah dengan ScaleButton
              ValueListenableBuilder<int>(
                valueListenable: _pageNotifier,
                builder: (context, page, _) {
                  return ScaleButton(
                    onTap: _next,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          page == 2 ? 'Get started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}