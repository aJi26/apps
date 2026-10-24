import 'package:flutter/material.dart';

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

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await ApiService.request('GET', 'profile');
    if (response.statusCode != 200) {
      throw StateError('Could not load your profile.');
    }
    final data = ApiService.decode(response);
    data['_token'] = await ApiService.getToken();
    return data;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _profile,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your profile could not load.'),
              TextButton(
                onPressed: () => setState(() => _profile = _load()),
                child: const Text('Try again'),
              ),
            ],
          ),
        );
      }
      final user = snapshot.data!['user'] as Map<String, dynamic>;
      final token = snapshot.data!['_token'] as String? ?? '';
      final avatarUrl = user['avatar_url'] as String?;
      return Scaffold(
        backgroundColor: AppTheme.current.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Settings Gerigi
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                      if (mounted) setState(() => _profile = _load());
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
                  backgroundImage: avatarUrl == null
                      ? null
                      : NetworkImage(
                          avatarUrl,
                          headers: {'Authorization': 'Bearer $token'},
                        ),
                  child: avatarUrl == null
                      ? Text(
                          user['avatar']?.toString() ?? '🌷',
                          style: const TextStyle(fontSize: 46),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user['name']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                user['email']?.toString() ?? '',
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
                        color: AppTheme.primary, // <-- Hapus kata 'const' di depan Icon
                      ),
                      title: const Text('Birthday'),
                      subtitle: Text(user['birthday']?.toString() ?? 'Not set'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.primary,
                      ),
                      title: const Text('Here since'),
                      subtitle: Text(user['joined']?.toString() ?? ''),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  if (mounted) setState(() => _profile = _load());
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _logout(BuildContext context) async {
    try {
      await ApiService.request('POST', 'logout');
    } catch (_) {}
    await ApiService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}