import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _picker = ImagePicker();
  DateTime? _birthday;
  String _avatar = '🌷';
  String? _existingAvatarUrl;
  String _token = '';
  File? _photo;
  bool _busy = true, _saving = false;
  static const _avatars = ['🌷', '🌼', '🌙', '🦋', '☁️'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _formatAvatarUrl(String? rawUrl) {
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
    return '$url${separator}t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _load() async {
    try {
      _token = await ApiService.getToken() ?? '';

      final response = await ApiService.request('GET', 'profile');
      if (response.statusCode != 200) {
        throw StateError('Could not load your profile.');
      }

      final data = ApiService.decode(response);
      final user = (data['user'] is Map ? data['user'] : data) as Map<String, dynamic>;

      _name.text = user['name']?.toString() ?? '';
      _avatar = user['avatar']?.toString() ?? '🌷';

      final rawUrl = user['avatar_url']?.toString() ?? user['avatar']?.toString();
      _existingAvatarUrl = _formatAvatarUrl(rawUrl);

      final raw = user['birthday_raw']?.toString() ?? user['birthday']?.toString();
      if (raw != null) _birthday = DateTime.tryParse(raw);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choosePhoto() async {
    final result = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (result != null && mounted) {
      setState(() {
        _photo = File(result.path);
        _existingAvatarUrl = null;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and birthday are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await ApiService.request(
        'PUT',
        'profile',
        body: {
          'name': _name.text.trim(),
          'birthday': _birthday!.toIso8601String().substring(0, 10),
          'avatar': _avatar,
        },
      );
      if (response.statusCode >= 300) {
        throw StateError(
          ApiService.decode(response)['message']?.toString() ??
              'Could not save your profile.',
        );
      }
      if (_photo != null) {
        final photoResponse = await ApiService.uploadAvatar(_photo!);
        if (photoResponse.statusCode >= 300) {
          throw StateError(
            ApiService.decode(photoResponse)['message']?.toString() ??
                'Could not upload your photo.',
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildAvatarPreview() {
    if (_photo != null) {
      return CircleAvatar(
        radius: 54,
        backgroundColor: AppTheme.sageSoft,
        backgroundImage: FileImage(_photo!),
      );
    }

    if (_existingAvatarUrl != null) {
      return Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.sageSoft,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            _existingAvatarUrl!,
            fit: BoxFit.cover,
            headers: _token.isNotEmpty ? {'Authorization': 'Bearer $_token'} : null,
            errorBuilder: (_, _, _) => Center(
              child: Text(_avatar, style: const TextStyle(fontSize: 42)),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 54,
      backgroundColor: AppTheme.sageSoft,
      child: Text(_avatar, style: const TextStyle(fontSize: 42)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    _buildAvatarPreview(),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        onPressed: _choosePhoto,
                        icon: const Icon(Icons.add_a_photo_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: _avatars
                    .map(
                      (item) => InkWell(
                        onTap: () => setState(() {
                          _avatar = item;
                          _photo = null;
                          _existingAvatarUrl = null;
                        }),
                        child: CircleAvatar(
                          backgroundColor:
                              _avatar == item && _photo == null && _existingAvatarUrl == null
                                  ? AppTheme.sageSoft
                                  : Colors.white,
                          child: Text(item),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                    initialDate: _birthday ?? DateTime(2000),
                  );
                  if (date != null) setState(() => _birthday = date);
                },
                icon: const Icon(Icons.cake_outlined),
                label: Text(
                  _birthday == null
                      ? 'Birthday'
                      : MaterialLocalizations.of(context)
                          .formatMediumDate(_birthday!),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}