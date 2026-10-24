import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

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
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  List<dynamic> _portraits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.request('GET', 'potret/gallery');
      if (response.statusCode < 300) {
        final data = ApiService.decode(response);
        setState(() => _portraits = data['portraits'] as List<dynamic>? ?? []);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _viewSnapshot(Map<String, dynamic> item) async {
    final imageUrl = item['image_url']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) return;
    final token = await ApiService.getToken();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  headers: {'Authorization': 'Bearer ${token ?? ''}'},
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Gagal memuat foto.'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ScaleButton(
                onTap: () => Navigator.pop(ctx),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.current.background,
      appBar: AppBar(title: const Text('Mood History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _portraits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = _portraits[idx];
                return ScaleButton(
                  onTap: () => _viewSnapshot(item),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.photo_outlined,
                        color: AppTheme.primary,
                      ),
                      title: Text(item['date']?.toString() ?? 'Snapshot Daily'),
                      subtitle: Text(item['time']?.toString() ?? ''),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                );
              },
            ),
    );
  }
}