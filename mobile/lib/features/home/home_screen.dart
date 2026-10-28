import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../daily_checkin/daily_checkin_screen.dart';
import '../finance/finance_screen.dart';
import '../goals/goals_screen.dart';
import '../mood_history/mood_history_screen.dart';
import '../music/music_screen.dart';
import '../notes/notes_screen.dart';
import '../profile/profile_screen.dart';
import '../randomizer/randomizer_screen.dart';
import '../wishlist/wishlist_screen.dart';

// Widget Animasi Sentuh Interaktif
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _user = {};
  Map<String, dynamic>? _mbtiData;
  String? _mbtiCode;
  bool _loading = true;
  int _selected = 0;
  String _token = '';
  int _cacheBuster = DateTime.now().millisecondsSinceEpoch;
  bool _hasCheckedPotret = false; // Flag mencegah popup ganda

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _load();

    NotificationService.syncFcmTokenWithBackend();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  (IconData, Color) _getGreetingIconInfo() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      // Pagi (05:00 - 10:59): Matahari Terbit
      return (Icons.wb_twilight_rounded, const Color(0xFFFFB74D));
    } else if (hour >= 11 && hour < 15) {
      // Siang (11:00 - 14:59): Matahari Terik
      return (Icons.wb_sunny_rounded, const Color(0xFFFFA000));
    } else if (hour >= 15 && hour < 18) {
      // Sore (15:00 - 17:59): Senja
      return (Icons.wb_sunny_outlined, const Color(0xFFFF7043));
    } else {
      // Malam (18:00 - 04:59): Bulan & Bintang
      return (Icons.nights_stay_rounded, const Color(0xFF7E57C2));
    }
  }

  String _getCleanGreeting() {
    final raw = _dashboard['greeting']?.toString() ?? 'Good day, lovely!';
    return raw.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}]', unicode: true), '').trim();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      _cacheBuster = DateTime.now().millisecondsSinceEpoch;

      if (!silent && _user.isEmpty) {
        if (mounted) setState(() => _loading = true);
      }

      _token = await ApiService.getToken() ?? '';

      final prefs = await SharedPreferences.getInstance();
      final localCode = prefs.getString('mbti_code');
      final localResult = prefs.getString('mbti_result');

      if (localCode != null && localCode.isNotEmpty) {
        _mbtiCode = localCode;
        if (localResult != null) {
          _mbtiData = jsonDecode(localResult) as Map<String, dynamic>;
        }
      }

      final results = await Future.wait([
        ApiService.request('GET', 'dashboard'),
        ApiService.request('GET', 'profile'),
        ApiService.request('GET', 'quiz/result'),
        ApiService.request('GET', 'potret/status'), // Pengecekan potret ditambah disini
      ]);

      if (results[0].statusCode == 200) {
        _dashboard = ApiService.decode(results[0]);
      }

      if (results[1].statusCode == 200) {
        final profileData = ApiService.decode(results[1]);
        if (profileData['user'] is Map<String, dynamic>) {
          _user = profileData['user'] as Map<String, dynamic>;
        }
      }

      if (results[2].statusCode == 200) {
        final quizData = ApiService.decode(results[2]);
        final rawResult = quizData['result'] ?? quizData['data'] ?? quizData;

        if (rawResult is Map<String, dynamic> && rawResult['scores'] != null) {
          _mbtiData = rawResult;
          _mbtiCode = _mbtiData?['code']?.toString() ??
              _mbtiData?['type']?.toString();

          if (_mbtiCode != null) {
            await prefs.setString('mbti_code', _mbtiCode!);
            await prefs.setString('mbti_result', jsonEncode(_mbtiData));
          }
        }
      }

      // 1. TAMBAHKAN PENGECEKAN STATUS POTRET DI SINI
      if (results[3].statusCode == 200 && !_hasCheckedPotret) {
         final potretData = ApiService.decode(results[3]);
         _hasCheckedPotret = true; // Set flag agar tidak loop popup

         // Jika statusnya belum completed, paksa buka CheckinScreen!
         if (potretData['completed'] == false && mounted) {
            // Gunakan postFrameCallback agar navigasi berjalan mulus setelah build selesai
            WidgetsBinding.instance.addPostFrameCallback((_) {
               Navigator.of(context).push(
                  MaterialPageRoute<void>(
                     builder: (_) => const DailyCheckinScreen(),
                  ),
               ).then((_) {
                 // Refresh dashboard setelah checkin ditutup
                 _load(silent: true); 
               });
            });
         }
      }

    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _getFormattedAvatarUrl() {
    final String? rawUrl = _user['avatar_url']?.toString();
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;

    String url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final baseUrl = ApiService.baseUrl
          .replaceAll('/api', '')
          .replaceAll('/api/', '');
      if (!url.startsWith('/')) url = '/$url';
      url = '$baseUrl$url';
    }

    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=$_cacheBuster';
  }

  String _getUserName() {
    return _user['name']?.toString() ?? 'Lovely User';
  }

  String _getUserEmail() {
    return _user['email']?.toString() ?? '';
  }

  void _open(String feature) {
    Widget screen;
    switch (feature) {
      case 'Notes':
        screen = const NotesScreen();
        break;
      case 'Goals':
        screen = const GoalsScreen();
        break;
      case 'Wishlist':
        screen = const WishlistScreen();
        break;
      case 'Finance':
        screen = const FinanceScreen();
        break;
      case 'Randomizer':
        screen = const RandomizerScreen();
        break;
      case 'Mood history':
        screen = const MoodHistoryScreen();
        break;
      case 'Music':
      default:
        screen = MusicScreen();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _showMbtiDetailDialog() {
    final primaryColor = AppTheme.current.primary;
    final sageSoftColor = AppTheme.current.sageSoft;
    final code = _mbtiCode ?? 'INFJ';
    final subtitle = _mbtiData?['subtitle']?.toString() ?? 'The Reflector';
    final scores = (_mbtiData?['scores'] as Map<String, dynamic>?) ?? {
      'E': 50,
      'I': 50,
      'S': 50,
      'N': 50,
      'T': 50,
      'F': 50,
      'J': 50,
      'P': 50,
    };

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const Text(
                                'Hasil Refleksi MBTI',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sageSoftColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              'Kuesioner ini cocok untuk refleksi diri dan mengenali preferensi pribadi, bukan instrumen MBTI® resmi maupun diagnosis psikologis.',
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryColor,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Rincian 4 Dimensi Preferensi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDimensionBar(
                      'Extraversion (E)',
                      scores['E'] ?? 0,
                      'Introversion (I)',
                      scores['I'] ?? 0,
                      primaryColor,
                      sageSoftColor,
                    ),
                    _buildDimensionBar(
                      'Sensing (S)',
                      scores['S'] ?? 0,
                      'Intuition (N)',
                      scores['N'] ?? 0,
                      primaryColor,
                      sageSoftColor,
                    ),
                    _buildDimensionBar(
                      'Thinking (T)',
                      scores['T'] ?? 0,
                      'Feeling (F)',
                      scores['F'] ?? 0,
                      primaryColor,
                      sageSoftColor,
                    ),
                    _buildDimensionBar(
                      'Judging (J)',
                      scores['J'] ?? 0,
                      'Perceiving (P)',
                      scores['P'] ?? 0,
                      primaryColor,
                      sageSoftColor,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curved.clamp(0.0, 1.0),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildDimensionBar(
    String leftLabel,
    dynamic leftVal,
    String rightLabel,
    dynamic rightVal,
    Color primaryColor,
    Color sageSoftColor,
  ) {
    final int left = (leftVal is num) ? leftVal.toInt() : 50;
    final int right = (rightVal is num) ? rightVal.toInt() : (100 - left);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$leftLabel ($left%)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$rightLabel ($right%)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: left / 100,
              backgroundColor: sageSoftColor,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileCard() {
    final primaryColor = AppTheme.current.primary;
    final sageSoftColor = AppTheme.current.sageSoft;
    final String? avatarUrl = _getFormattedAvatarUrl();
    final String name = _getUserName();
    final String email = _getUserEmail();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sageSoftColor,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          key: ValueKey(_cacheBuster),
                          headers: _token.isNotEmpty
                              ? {'Authorization': 'Bearer $_token'}
                              : null,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text('🌷', style: TextStyle(fontSize: 40)),
                          ),
                        )
                      : const Center(
                          child: Text('🌷', style: TextStyle(fontSize: 40)),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E35),
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _onTabSelected(3);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Lihat Profil Lengkap',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickAdd() {
    final primaryColor = AppTheme.current.primary;
    final backgroundColor = AppTheme.current.background;

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: backgroundColor,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Make a little space',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              for (final item in [
                ('Add a note', Icons.edit_note, 'Notes'),
                ('Add a goal', Icons.flag_outlined, 'Goals'),
                ('Add a wishlist item', Icons.card_giftcard, 'Wishlist'),
                ('Add transaction', Icons.account_balance_wallet_outlined, 'Finance'),
                ('Take today’s photo', Icons.camera_alt_outlined, 'Snapshot'),
              ])
                ListTile(
                  leading: Icon(item.$2, color: primaryColor),
                  title: Text(item.$1),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (item.$3 == 'Snapshot') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DailyCheckinScreen(),
                        ),
                      );
                    } else {
                      _open(item.$3);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() => _selected = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    if (index == 0) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final primaryColor = AppTheme.current.primary;
    final pages = [
      _homeBody(),
      _lifeBody(),
      MusicScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _selected = index);
            if (index == 0) _load(silent: true);
          },
          children: pages,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _quickAdd,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBuilder(
        animation: _pageController,
        builder: (context, _) {
          double currentPage = _selected.toDouble();
          if (_pageController.hasClients &&
              _pageController.position.haveDimensions) {
            currentPage = _pageController.page ?? _selected.toDouble();
          }

          return BottomAppBar(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            height: 76,
            padding: EdgeInsets.zero,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                const gapWidth = 54.0;
                final tabWidth = (totalWidth - gapWidth) / 4;
                const pillWidth = 50.0;

                final basePad = (tabWidth - pillWidth) / 2;
                double leftOffset;

                if (currentPage <= 1.0) {
                  leftOffset = currentPage * tabWidth + basePad;
                } else if (currentPage <= 2.0) {
                  leftOffset = (1.0 * tabWidth + basePad) +
                      (currentPage - 1.0) * (tabWidth + gapWidth);
                } else {
                  leftOffset = (2.0 * tabWidth + gapWidth + basePad) +
                      (currentPage - 2.0) * tabWidth;
                }

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: leftOffset,
                      top: 15.0,
                      child: Container(
                        width: 50.0,
                        height: 32.0,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _nav(Icons.home_outlined, Icons.home_rounded, 'Home', 0, currentPage),
                        _nav(Icons.favorite_border, Icons.favorite_rounded, 'Life', 1, currentPage),
                        const SizedBox(width: gapWidth),
                        _nav(Icons.music_note_outlined, Icons.music_note_rounded, 'Fun', 2, currentPage),
                        _nav(Icons.person_outline, Icons.person_rounded, 'Profile', 3, currentPage),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _nav(
    IconData iconOutline,
    IconData iconFilled,
    String label,
    int index,
    double currentPage,
  ) {
    final primaryColor = AppTheme.current.primary;
    
    final double activeProgress =
        (1.0 - (currentPage - index).abs()).clamp(0.0, 1.0);

    final color = Color.lerp(AppTheme.textMuted, primaryColor, activeProgress)!;

    return Expanded(
      child: ScaleButton(
        onTap: () => _onTabSelected(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 30,
                child: Center(
                  child: Icon(
                    activeProgress > 0.5 ? iconFilled : iconOutline,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: activeProgress > 0.5
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeBody() {
    final String? avatarUrl = _getFormattedAvatarUrl();
    final primaryColor = AppTheme.current.primary;
    final sageSoftColor = AppTheme.current.sageSoft;
    final greetingIconInfo = _getGreetingIconInfo();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _getCleanGreeting(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          greetingIconInfo.$1,
                          color: greetingIconInfo.$2,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dashboard['date']?.toString() ?? '',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ScaleButton(
                onTap: _showProfileCard,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sageSoftColor,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(
                            avatarUrl,
                            key: ValueKey(_cacheBuster),
                            headers: _token.isNotEmpty
                                ? {'Authorization': 'Bearer $_token'}
                                : null,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Text('🌷', style: TextStyle(fontSize: 30)),
                            ),
                          )
                        : const Center(
                            child: Text('🌷', style: TextStyle(fontSize: 30)),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_mbtiCode != null && _mbtiCode!.isNotEmpty) ...[
            ScaleButton(
              onTap: _showMbtiDetailDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: sageSoftColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('✨ ', style: TextStyle(fontSize: 14)),
                    Text(
                      _mbtiCode!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '•  ${_mbtiData?['subtitle']?.toString() ?? 'Personality Type'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Icon(
                  greetingIconInfo.$1,
                  color: greetingIconInfo.$2,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today’s little thing',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _dashboard['today_quote']?.toString() ??
                            'Take a soft breath. You’re doing enough.',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          _sectionTitle('Quick Access'),
          const SizedBox(height: 14),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: [
              _shortcut(
                Icons.music_note_rounded,
                'Music',
                const Color(0xFFF0E6FF),
                const Color(0xFF7E57C2),
              ),
              _shortcut(
                Icons.edit_note_rounded,
                'Notes',
                const Color(0xFFFFF3E0),
                const Color(0xFFFB8C00),
              ),
              // Tombol Goals diganti ke Warm Mocha / Soft Chocolate
              _shortcut(
                Icons.flag_rounded,
                'Goals',
                const Color(0xFFF5EBE6),
                const Color(0xFF8D6E63),
              ),
              _shortcut(
                Icons.card_giftcard_rounded,
                'Wishlist',
                const Color(0xFFFCE4EC),
                const Color(0xFFEC407A),
              ),
              _shortcut(
                Icons.account_balance_wallet_rounded,
                'Finance',
                const Color(0xFFE0F2F1),
                const Color(0xFF00897B),
              ),
              _shortcut(
                Icons.auto_awesome_rounded,
                'Randomizer',
                const Color(0xFFE3F2FD),
                const Color(0xFF42A5F5),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _sectionTitle('Your gentle progress'),
          const SizedBox(height: 10),

          Row(
            children: [
              _stat(
                _dashboard['summary']?['active_goals'] ?? 0,
                'Active goals',
                primaryColor,
              ),
              const SizedBox(width: 8),
              _stat(
                _dashboard['summary']?['wishlist_items'] ?? 0,
                'Wishlist',
                primaryColor,
              ),
              const SizedBox(width: 8),
              _stat(
                _dashboard['summary']?['notes_count'] ?? 0,
                'Notes',
                primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 20),

          ScaleButton(
            onTap: () => _open('Mood history'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: sageSoftColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your daily check-in',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Today you’re feeling ${_dashboard['current_mood'] ?? 'ready to begin'}.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lifeBody() {
    final primaryColor = AppTheme.current.primary;
    final sageSoftColor = AppTheme.current.sageSoft;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Your life, at your pace',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        for (final item in [
          ('Notes', 'A safe place for your thoughts.', Icons.edit_note),
          ('Goals', 'Little steps become big things.', Icons.flag_outlined),
          (
            'Wishlist',
            'Keep the things you’re dreaming of.',
            Icons.card_giftcard,
          ),
          (
            'Finance',
            'Track your income, expenses & savings.',
            Icons.account_balance_wallet_outlined,
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ScaleButton(
              onTap: () => _open(item.$1),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: sageSoftColor,
                      child: Icon(item.$3, color: primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      );

  Widget _shortcut(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
  ) =>
      ScaleButton(
        onTap: () => _open(label),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _stat(dynamic value, String label, Color primaryColor) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
}