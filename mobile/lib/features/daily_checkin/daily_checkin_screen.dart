import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});
  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  static const _moods = [
    ('😄', 'Amazing'),
    ('🙂', 'Good'),
    ('😌', 'Calm'),
    ('😴', 'Tired'),
    ('🙁', 'Not great'),
  ];
  String? _mood;
  bool _saving = false;

  Future<void> _continue() async {
    if (_mood == null) return;
    setState(() => _saving = true);
    try {
      final response = await ApiService.request(
        'POST',
        'dashboard/mood',
        body: {'mood': _mood},
      );
      if (response.statusCode >= 300) {
        throw StateError(
          ApiService.decode(response)['message']?.toString() ??
              'Could not save your mood.',
        );
      }
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const SnapshotScreen()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false, // KUNCI BACK BUTTON (ANTI-BYPASS)
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'How are you\nfeeling today?',
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Take a gentle moment to check in with yourself.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  for (final mood in _moods)
                    Card(
                      color: _mood == mood.$2 ? AppTheme.sageSoft : Colors.white,
                      child: ListTile(
                        minVerticalPadding: 9,
                        onTap: () => setState(() => _mood = mood.$2),
                        leading: Text(mood.$1, style: const TextStyle(fontSize: 28)),
                        title: Text(mood.$2),
                        trailing: _mood == mood.$2
                            ? const Icon(Icons.check_circle, color: AppTheme.primary)
                            : null,
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _mood == null || _saving ? null : _continue,
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class SnapshotScreen extends StatefulWidget {
  const SnapshotScreen({super.key});
  @override
  State<SnapshotScreen> createState() => _SnapshotScreenState();
}

class _SnapshotScreenState extends State<SnapshotScreen> with WidgetsBindingObserver {
  CameraController? _camera;
  XFile? _photo;
  String? _error;
  bool _opening = true, _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openFrontCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _camera;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _camera = null;
      controller?.dispose();
      if (mounted && _photo == null) setState(() => _opening = true);
    } else if (state == AppLifecycleState.resumed && _photo == null) {
      _openFrontCamera();
    }
  }

  Future<void> _openFrontCamera() async {
    if (!mounted) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await _camera?.dispose();
      _camera = null;
      final cameras = await availableCameras();
      final front = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.front)
          .firstOrNull;
      if (front == null) {
        throw CameraException('FrontCameraUnavailable', 'Device does not have front camera.');
      }
      final controller = CameraController(
        front,
        ResolutionPreset.ultraHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _opening = false;
      });
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.description ?? 'Camera permission is required.';
          _opening = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not open camera.';
          _opening = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || camera.value.isTakingPicture) {
      return;
    }
    try {
      final image = await camera.takePicture();
      if (mounted) setState(() => _photo = image);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The photo could not be captured. Try again.')),
        );
      }
    }
  }

  Future<void> _send() async {
    final photo = _photo;
    if (photo == null) return;
    setState(() => _sending = true);
    try {
      final response = await ApiService.uploadPortrait(File(photo.path));
      if (response.statusCode < 300 && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        throw StateError(
          ApiService.decode(response)['message']?.toString() ?? 'Upload failed.',
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false, // KUNCI BACK BUTTON (ANTI-BYPASS)
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Text(
                    'Today’s Snapshot',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'A little moment, just as you are.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        color: AppTheme.sageSoft,
                        width: double.infinity,
                        child: _photo != null
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi), // UN-MIRROR RESULT
                                child: Image.file(File(_photo!.path), fit: BoxFit.cover),
                              )
                            : _opening
                                ? const Center(child: CircularProgressIndicator())
                                : _error != null
                                    ? Center(child: Text(_error!))
                                    : Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.rotationY(math.pi), // UN-MIRROR PREVIEW
                                        child: CameraPreview(_camera!),
                                      ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_photo == null)
                    ElevatedButton.icon(
                      onPressed: _opening || _error != null ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take today’s photo'),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _sending ? null : () => setState(() => _photo = null),
                            child: const Text('Retake'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sending ? null : _send,
                            child: _sending
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Send'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}