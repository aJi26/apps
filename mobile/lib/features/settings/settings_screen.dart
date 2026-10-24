import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Account State
  String _userName = '';
  String _userEmail = '';
  bool _loadingUser = true;

  // Notification Toggles
  bool _checkinReminders = true;
  bool _activityReminders = true;
  bool _birthdayWishes = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _checkinReminders = prefs.getBool('notif_checkin') ?? true;
      _activityReminders = prefs.getBool('notif_activity') ?? true;
      _birthdayWishes = prefs.getBool('notif_birthday') ?? true;

      final res = await ApiService.request('GET', 'profile');
      if (res.statusCode == 200) {
        final data = ApiService.decode(res);
        final user = (data['user'] is Map ? data['user'] : data) as Map<String, dynamic>;
        _userName = user['name']?.toString() ?? '';
        _userEmail = user['email']?.toString() ?? '';
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _toggleNotif(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
    setState(() {
      if (key == 'notif_checkin') _checkinReminders = val;
      if (key == 'notif_activity') _activityReminders = val;
      if (key == 'notif_birthday') _birthdayWishes = val;
    });
  }

  void _showEditAccountDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'user@herspace.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final email = emailController.text.trim().toLowerCase();

                      if (name.isEmpty || email.isEmpty) return;

                      if (!email.endsWith('@herspace.com')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email wajib menggunakan domain @herspace.com'),
                          ),
                        );
                        return;
                      }

                      setModalState(() => saving = true);
                      try {
                        final res = await ApiService.request(
                          'PUT',
                          'profile',
                          body: {
                            'name': name,
                            'email': email,
                          },
                        );
                        if (res.statusCode < 300) {
                          setState(() {
                            _userName = name;
                            _userEmail = email;
                          });
                          if (mounted) Navigator.pop(dialogCtx);
                        } else {
                          final errData = ApiService.decode(res);
                          throw StateError(errData['message']?.toString() ?? 'Failed to update account.');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        setModalState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassword,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setModalState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassword,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_open_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setModalState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassword,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.check_circle_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: saving
                  ? null
                  : () async {
                      if (newPassword.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters.')),
                        );
                        return;
                      }
                      if (newPassword.text != confirmPassword.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match.')),
                        );
                        return;
                      }
                      setModalState(() => saving = true);
                      try {
                        final res = await ApiService.request(
                          'POST',
                          'change-password',
                          body: {
                            'old_password': oldPassword.text,
                            'new_password': newPassword.text,
                          },
                        );
                        if (res.statusCode < 300) {
                          if (mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated successfully!')),
                            );
                          }
                        } else {
                          final data = ApiService.decode(res);
                          throw StateError(data['message']?.toString() ?? 'Failed to update password.');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        setModalState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeKey = AppTheme.currentThemeNotifier.value;

    return Scaffold(
      backgroundColor: AppTheme.current.background,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionHeader('Account'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person_outline, color: AppTheme.current.primary),
                        title: const Text('Account Details'),
                        subtitle: Text(_userEmail.isNotEmpty ? '$_userName • $_userEmail' : _userName),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: _showEditAccountDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.lock_outline, color: AppTheme.current.primary),
                        title: const Text('Change Password'),
                        subtitle: const Text('Security & credentials'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: _showChangePasswordDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader('Notifications'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _checkinReminders,
                        activeColor: AppTheme.current.primary,
                        title: const Text('Daily Check-in Reminder'),
                        subtitle: const Text('Evening prompt to log your mood & thoughts'),
                        onChanged: (val) => _toggleNotif('notif_checkin', val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _activityReminders,
                        activeColor: AppTheme.current.primary,
                        title: const Text('Activity & Goals Reminders'),
                        subtitle: const Text('Updates on notes, goals & wishlist items'),
                        onChanged: (val) => _toggleNotif('notif_activity', val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _birthdayWishes,
                        activeColor: AppTheme.current.primary,
                        title: const Text('Birthday Celebration'),
                        subtitle: const Text('Receive special wishes on your birthday'),
                        onChanged: (val) => _toggleNotif('notif_birthday', val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader('Appearance & Theme'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose your space palette',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          children: AppThemeKey.values.map((key) {
                            final preset = AppTheme.presets[key]!;
                            final isSelected = activeThemeKey == key;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => AppTheme.setTheme(key),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: preset.background,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? preset.primary : preset.border,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: preset.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: preset.sageSoft,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          preset.name,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: preset.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: preset.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}