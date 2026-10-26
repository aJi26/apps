import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _user;
  String _token = '';
  String? _cachedAvatarUrl;
  bool _loading = true;
  bool _hasError = false;
  int _cacheBuster = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({bool silent = false, bool forceRefreshImage = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Muat data dari cache lokal jika ada
    final cachedUserJson = prefs.getString('cached_user_profile');
    if (cachedUserJson != null && _user == null) {
      try {
        final cachedMap = jsonDecode(cachedUserJson) as Map<String, dynamic>;
        final token = await ApiService.getToken() ?? '';
        if (mounted) {
          setState(() {
            _user = cachedMap;
            _token = token;
            _cachedAvatarUrl = _buildAvatarUrl(_user?['avatar_url']?.toString());
            _loading = false;
          });
        }
      } catch (_) {}
    }

    if (!silent && _user == null) {
      if (mounted) {
        setState(() {
          _loading = true;
          _hasError = false;
        });
      }
    }

    try {
      // 2. Perbarui cache buster HANYA jika dipicu edit profil / pull-to-refresh
      if (forceRefreshImage) {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        _cacheBuster = DateTime.now().millisecondsSinceEpoch;
      }

      final response = await ApiService.request('GET', 'profile');
      if (response.statusCode != 200) {
        throw StateError('Could not load your profile.');
      }
      final data = ApiService.decode(response);
      final user = (data['user'] is Map ? data['user'] : data) as Map<String, dynamic>;
      final token = await ApiService.getToken() ?? '';

      await prefs.setString('cached_user_profile', jsonEncode(user));

      if (mounted) {
        setState(() {
          _user = user;
          _token = token;
          _cachedAvatarUrl = _buildAvatarUrl(user['avatar_url']?.toString());
          _loading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_user == null) _hasError = true;
        });
      }
    }
  }

  String? _buildAvatarUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    String url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '').replaceAll('/api/', '');
      if (!url.startsWith('/')) url = '/$url';
      url = '$baseUrl$url';
    }

    // Jika ada penanda refresh gambar, baru tempelkan timestamp
    if (_cacheBuster > 0) {
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}t=$_cacheBuster';
    }
    return url;
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await ApiService.request('POST', 'logout');
    } catch (_) {}
    
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_profile');

    await ApiService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading && _user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError && _user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your profile could not load.'),
              TextButton(
                onPressed: () => _loadProfile(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.current.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadProfile(silent: true, forceRefreshImage: true),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                      if (mounted) _loadProfile(silent: true);
                    },
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                  ),
                  IconButton(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    tooltip: 'Log out',
                  ),
                ],
              ),
              Center(
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: AppTheme.sageSoft,
                  backgroundImage: _cachedAvatarUrl == null
                      ? null
                      : NetworkImage(
                          _cachedAvatarUrl!,
                          headers: _token.isNotEmpty
                              ? {'Authorization': 'Bearer $_token'}
                              : null,
                        ),
                  child: _cachedAvatarUrl == null
                      ? Text(
                          _user!['avatar']?.toString() ?? '🌷',
                          style: const TextStyle(fontSize: 46),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _user!['name']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                _user!['email']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 22),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.cake_outlined,
                        color: AppTheme.primary,
                      ),
                      title: const Text('Birthday'),
                      subtitle: Text(_user!['birthday']?.toString() ?? 'Not set'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.primary,
                      ),
                      title: const Text('Here since'),
                      subtitle: Text(_user!['joined']?.toString() ?? ''),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  if (updated == true && mounted) {
                    _loadProfile(silent: true, forceRefreshImage: true);
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}