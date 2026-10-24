import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/routing/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _picker = ImagePicker();
  DateTime? _birthday;
  String _avatar = '🌷';
  File? _photo;
  bool _busy = false;
  final _avatars = const ['🌷', '🌼', '🌙', '🦋', '☁️'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) return; // Pengguna membatalkan pilih gambar

      // Jalankan proses Crop & Scale
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Atur Foto Profil',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Atur Foto Profil',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() => _photo = File(croppedFile.path));
      } else if (mounted) {
        // Fallback: Jika cropping gagal/dilewati, pakai foto asli
        setState(() => _photo = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses gambar: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add your name and birthday to continue.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await ApiService.request(
        'POST',
        'profile-setup',
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
        final avatarResponse = await ApiService.uploadAvatar(_photo!);
        if (avatarResponse.statusCode >= 300) {
          throw StateError(
            ApiService.decode(avatarResponse)['message']?.toString() ??
                'Could not upload your photo.',
          );
        }
      }
      if (!mounted) return;
      final gateResult = await AppRouter.resolve(context);
      if (!mounted) return;
      if (gateResult == GateResult.retry) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile saved. Please check your connection and continue again.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Let’s make this yours',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'A few little details to get started.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppTheme.sageSoft,
                    backgroundImage: _photo == null ? null : FileImage(_photo!),
                    child: _photo == null
                        ? Text(_avatar, style: const TextStyle(fontSize: 44))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      tooltip: 'Choose a photo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 10,
                children: _avatars
                    .map(
                      (item) => InkWell(
                        onTap: () => setState(() {
                          _avatar = item;
                          _photo = null;
                        }),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: _avatar == item && _photo == null
                              ? AppTheme.sageSoft
                              : Colors.white,
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name',
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
                  initialDate: DateTime(2000),
                );
                if (date != null) setState(() => _birthday = date);
              },
              icon: const Icon(Icons.cake_outlined),
              label: Text(
                _birthday == null
                    ? 'Choose your birthday'
                    : MaterialLocalizations.of(context)
                          .formatMediumDate(_birthday!),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    ),
  );
}