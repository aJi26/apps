import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/api_service.dart';

class RandomizerScreen extends StatefulWidget {
  const RandomizerScreen({super.key});

  @override
  State<RandomizerScreen> createState() => _RandomizerScreenState();
}

class _RandomizerScreenState extends State<RandomizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _logoEntranceScale;
  late Animation<double> _logoShrinkScale;
  late Animation<Offset> _logoSlide;
  late Animation<double> _quoteOpacity;

  // Collection ide refleksi berbahasa Inggris
  final List<Map<String, dynamic>> _ideasPool = [
    {
      'title': 'Take a Gentle Pause',
      'text': 'Take three deep breaths. Let go of what you cannot control right now.',
    },
    {
      'title': 'Little Warmth',
      'text': 'Enjoy a warm cup of tea or water. Feel the quiet comfort around you.',
    },
    {
      'title': 'Self Appreciation',
      'text': 'Name three little things you accomplished today, no matter how small.',
    },
    {
      'title': 'Gentle Reminder',
      'text': 'You don’t have to finish everything today. Just take it one step at a time.',
    },
    {
      'title': 'Kindness Spark',
      'text': 'Send a sweet message or warm emoji to a friend you haven’t talked to in a while.',
    },
    {
      'title': 'Unplug & Breathe',
      'text': 'Rest your eyes from screens for five minutes. Look out the window and feel the air.',
    },
    {
      'title': 'Mindful Moment',
      'text': 'Listen to your favorite song without doing anything else. Just feel the melody.',
    },
    {
      'title': 'Soft Words',
      'text': 'Tell yourself: "I am doing my best, and that is already enough."',
    },
    {
      'title': 'Embrace the Quiet',
      'text': 'Give yourself permission to sit in silence for a few peaceful moments.',
    },
    {
      'title': 'Small Victories',
      'text': 'Celebrate the fact that you showed up for yourself today.',
    },
  ];

  Map<String, dynamic>? _currentIdea;
  bool _isFetchingBackground = false;

  @override
  void initState() {
    super.initState();
    _currentIdea = _ideasPool.first;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 1. Animasi Logo Muncul Membesar di Tengah
    _logoEntranceScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // 2. Animasi Logo Meluncur Naik Ke Posisi Lingkaran Oranye Atas
    _logoSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.60),
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Logo Mengecil Pas Meluncur Ke Atas
    _logoShrinkScale = Tween<double>(begin: 1.0, end: 0.65).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Kartu Pernyataan Teks Muncul di Bawah Logo
    _quoteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.70, 1.0, curve: Curves.easeIn),
      ),
    );

    _animController.forward();
    _fetchApiIdea();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchApiIdea() async {
    if (_isFetchingBackground) return;
    _isFetchingBackground = true;

    try {
      final response = await ApiService.request('GET', 'randomizer');
      if (response.statusCode < 300) {
        final data = ApiService.decode(response);
        final idea = data['idea'] as Map<String, dynamic>?;
        if (idea != null && mounted) {
          _ideasPool.add(idea);
        }
      }
    } catch (_) {
      // Fallback ke local pool
    } finally {
      _isFetchingBackground = false;
    }
  }

  void _nextIdea() {
    if (_ideasPool.isEmpty) return;

    final random = Random();
    int nextIndex;
    do {
      nextIndex = random.nextInt(_ideasPool.length);
    } while (_ideasPool.length > 1 &&
        _ideasPool[nextIndex]['text'] == _currentIdea?['text']);

    setState(() {
      _currentIdea = _ideasPool[nextIndex];
    });

    _fetchApiIdea();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _nextIdea, // Tap di seluruh area layar untuk ganti ide
        child: Stack(
          children: [
            // 1. Latar Belakang SVG
            Positioned.fill(
              child: SvgPicture.asset(
                'lib/assets/image/random.svg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholderBuilder: (context) => Container(
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ),

            // 2. Overlay Gelap
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),

            // 3. Konten Utama
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Header Atas
                    const SizedBox(height: 10),
                    const Text(
                      'Randomize',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap anywhere on the screen for a new reflection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),

                    const Spacer(flex: 1), // Pendorong atas

                    // Logo Lingkaran (Animasi Membesar -> Meluncur Ke Atas Oranye)
                    SlideTransition(
                      position: _logoSlide,
                      child: ScaleTransition(
                        scale: _logoEntranceScale,
                        child: ScaleTransition(
                          scale: _logoShrinkScale,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF7ECE1),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 48,
                                color: Color(0xFF8E6B58),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Kartu Pernyataan Pink Transparan (Posisi Tepat di Bawah Logo yang Meluncur)
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: FadeTransition(
                        opacity: _quoteOpacity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.96, end: 1.0)
                                    .animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey(_currentIdea?['text'] ?? 'default_key'),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 22,
                            ),
                            decoration: BoxDecoration(
                              // Pink Transparan Soft
                              color: const Color(0xFFFAD2E1).withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _currentIdea?['title']?.toString() ??
                                            'Today\'s Little Thing',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _currentIdea?['text']?.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2), // Menjaga posisi tetap di area tengah-atas
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}