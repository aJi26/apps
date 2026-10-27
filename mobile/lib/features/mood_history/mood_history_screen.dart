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
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_portraits.isEmpty) setState(() => _loading = true);
    try {
      _token = await ApiService.getToken();
      final response = await ApiService.request('GET', 'potret/gallery');

      if (response.statusCode < 300) {
        final data = ApiService.decode(response);

        // Toleransi struktur JSON (portraits / data / direct list)
        final rawList = data['portraits'] ?? data['data'] ?? (data is List ? data : []);

        if (mounted) {
          setState(() {
            _portraits = rawList is List ? rawList : [];
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Format URL gambar agar selalu valid (termasuk jika dari domain Render)
  String? _formatImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    String url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '').replaceAll('/api/', '');
      if (!url.startsWith('/')) url = '/$url';
      url = '$baseUrl$url';
    }
    return url;
  }

  Future<void> _viewSnapshot(Map<String, dynamic> item) async {
    final rawUrl = item['image_url']?.toString() ??
        item['photo_url']?.toString() ??
        item['url']?.toString() ??
        item['path']?.toString();

    final imageUrl = _formatImageUrl(rawUrl);

    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL foto tidak ditemukan.')),
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  headers: _token != null && _token!.isNotEmpty
                      ? {'Authorization': 'Bearer $_token'}
                      : null,
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
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: _portraits.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'Belum ada riwayat foto snapshot.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _portraits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final item = _portraits[idx] as Map<String, dynamic>;
                        final rawUrl = item['image_url']?.toString() ??
                            item['photo_url']?.toString() ??
                            item['url']?.toString() ??
                            item['path']?.toString();

                        final imageUrl = _formatImageUrl(rawUrl);

                        final dateText = item['date']?.toString() ??
                            item['tanggal']?.toString() ??
                            item['created_at']?.toString().split('T').first ??
                            'Snapshot Daily';

                        final timeText = item['time']?.toString() ??
                            item['jam']?.toString() ??
                            item['mood']?.toString() ??
                            '';

                        return ScaleButton(
                          onTap: () => _viewSnapshot(item),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl != null
                                    ? Image.network(
                                        imageUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        headers: _token != null && _token!.isNotEmpty
                                            ? {'Authorization': 'Bearer $_token'}
                                            : null,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.photo_outlined,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.photo_outlined,
                                        color: AppTheme.primary,
                                      ),
                              ),
                              title: Text(
                                dateText,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(timeText),
                              trailing: const Icon(Icons.chevron_right_rounded),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}