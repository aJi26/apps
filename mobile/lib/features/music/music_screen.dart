import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  bool _loading = true;
  bool _shufflingDaily = false;
  String _currentMood = 'Calm';

  Map<String, dynamic>? _dailyTrack;
  List<dynamic> _categories = [];
  List<dynamic> _communityPlaylists = [];
  List<dynamic> _myPlaylists = [];

  bool _loadingDaily = true;
  bool _loadingCategories = true;
  bool _loadingCommunity = true;
  bool _loadingMyPlaylists = true;

  @override
  void initState() {
    super.initState();
    _loadMusicData();
  }

  // Load data secara progresif agar UI tidak tertahan penuh
  Future<void> _loadMusicData() async {
    if (mounted) {
      setState(() {
        _loading = false;
        _loadingDaily = true;
        _loadingCategories = true;
        _loadingCommunity = true;
        _loadingMyPlaylists = true;
      });
    }

    _fetchDailyTrack();
    _fetchCategories();
    _fetchCommunityPlaylists();
    _fetchMyPlaylists();
  }

  Future<void> _fetchDailyTrack() async {
    try {
      final res = await ApiService.request('GET', 'music/daily');
      if (res.statusCode == 200 && mounted) {
        final data = ApiService.decode(res);
        setState(() {
          _currentMood = data['mood']?.toString() ?? 'Calm';
          _dailyTrack = data['recommendation'] as Map<String, dynamic>?;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDaily = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService.request('GET', 'music/categories');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _categories = ApiService.decode(res)['categories'] as List<dynamic>? ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _fetchCommunityPlaylists() async {
    try {
      final res = await ApiService.request('GET', 'music/community-playlists');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _communityPlaylists = ApiService.decode(res)['playlists'] as List<dynamic>? ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCommunity = false);
    }
  }

  Future<void> _fetchMyPlaylists() async {
    try {
      final res = await ApiService.request('GET', 'music/my-playlists');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _myPlaylists = ApiService.decode(res)['my_playlists'] as List<dynamic>? ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMyPlaylists = false);
    }
  }

  Future<void> _shuffleDailyOnly() async {
    if (_shufflingDaily) return;
    setState(() => _shufflingDaily = true);

    try {
      final response = await ApiService.request('GET', 'music/daily');
      if (response.statusCode == 200) {
        final data = ApiService.decode(response);
        if (mounted) {
          setState(() {
            _currentMood = data['mood']?.toString() ?? 'Calm';
            _dailyTrack = data['recommendation'] as Map<String, dynamic>?;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _shufflingDaily = false);
    }
  }

  Future<void> _openUrl(
    String? urlString, {
    String? uriString,
    String? searchQuery,
    String platform = 'spotify',
  }) async {
    if (platform == 'spotify' && uriString != null && uriString.trim().isNotEmpty) {
      try {
        final Uri appUri = Uri.parse(uriString.trim());
        if (await canLaunchUrl(appUri)) {
          final launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
          if (launched) return;
        }
      } catch (_) {}
    }

    if (urlString != null && urlString.trim().isNotEmpty) {
      try {
        final Uri webUri = Uri.parse(urlString.trim());
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}
    }

    if (searchQuery != null &&
        searchQuery.trim().isNotEmpty &&
        !searchQuery.contains('Lagu Spesial Hari Ini')) {
      final encoded = Uri.encodeComponent(searchQuery.trim());
      final searchUrl = platform == 'spotify'
          ? 'https://open.spotify.com/search/$encoded/playlists'
          : 'https://music.youtube.com/search?q=$encoded';
      
      try {
        await launchUrl(Uri.parse(searchUrl), mode: LaunchMode.externalApplication);
      } catch (_) {}
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data lagu dari server belum siap. Tarik layar ke bawah untuk refresh.'),
          ),
        );
      }
    }
  }

  Future<void> _deletePlaylist(dynamic id) async {
    final response = await ApiService.request('DELETE', 'music/my-playlists/$id');
    if (response.statusCode < 300) {
      await _fetchMyPlaylists();
    }
  }

  Future<void> _deleteTrack(dynamic trackId) async {
    final response = await ApiService.request('DELETE', 'music/my-playlists/tracks/$trackId');
    if (response.statusCode < 300) {
      await _fetchMyPlaylists();
    }
  }

  void _createPlaylistModal() {
    final titleController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.background,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buat Playlist Baru', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Nama Playlist (misal: Mood Chill)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty) {
                    final response = await ApiService.request(
                      'POST',
                      'music/my-playlists',
                      body: {'title': title},
                    );
                    if (mounted) Navigator.pop(ctx);
                    if (response.statusCode < 300) {
                      await _fetchMyPlaylists();
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal membuat playlist.')),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTrackModal(dynamic playlistId) {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    final urlController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.background,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tambah Lagu / Link', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'Judul Lagu'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: artistController,
              decoration: const InputDecoration(hintText: 'Penyanyi / Band'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: 'Link Spotify / YouTube'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                    final response = await ApiService.request(
                      'POST',
                      'music/my-playlists/$playlistId/tracks',
                      body: {
                        'title': titleController.text.trim(),
                        'artist': artistController.text.trim(),
                        'url': urlController.text.trim(),
                      },
                    );
                    if (mounted) Navigator.pop(ctx);
                    if (response.statusCode < 300) {
                      await _fetchMyPlaylists();
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menambah lagu.')),
                      );
                    }
                  }
                },
                child: const Text('Tambahkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.current.background,
      appBar: AppBar(title: const Text('Music & Mood Vibe')),
      body: RefreshIndicator(
        onRefresh: _loadMusicData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader("Today's Vibe ($_currentMood)"),
            const SizedBox(height: 10),
            _buildDailyBanner(),
            const SizedBox(height: 24),

            _sectionHeader('Explore Genres'),
            const SizedBox(height: 12),
            _buildGenreList(),
            const SizedBox(height: 24),

            _sectionHeader('Community Playlists'),
            const SizedBox(height: 12),
            _buildCommunitySection(),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader('My Playlists'),
                IconButton(
                  onPressed: _createPlaylistModal,
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMyPlaylists(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35)),
    );
  }

  Widget _buildDailyBanner() {
    if (_loadingDaily) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
        ),
      );
    }

    final title = _dailyTrack?['title']?.toString() ?? 'Lagu Spesial Hari Ini';
    final artist = _dailyTrack?['artist']?.toString() ?? 'Artis Pilihan';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '✨ Cocok untuk suasana $_currentMood',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: _shufflingDaily
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      )
                    : const Icon(Icons.shuffle_rounded, size: 20, color: AppTheme.primary),
                onPressed: _shuffleDailyOnly,
                tooltip: 'Acak Lagu Ini',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E35),
            ),
          ),
          Text(artist, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openUrl(
                    _dailyTrack?['url_spotify']?.toString(),
                    uriString: _dailyTrack?['uri_spotify']?.toString(),
                    searchQuery: '$title $artist',
                    platform: 'spotify',
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Spotify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openUrl(
                    _dailyTrack?['url_youtube']?.toString(),
                    searchQuery: '$title $artist',
                    platform: 'youtube',
                  ),
                  icon: const Icon(Icons.music_note_rounded),
                  label: const Text('YouTube'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGenreList() {
    if (_loadingCategories) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Belum ada genre tersedia.', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    return Column(
      children: _categories.map<Widget>((cat) {
        final genre = cat['genre']?.toString() ?? 'Genre';
        final tracks = (cat['tracks'] as List<dynamic>?) ?? [];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            title: Text(genre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            leading: const Icon(Icons.queue_music_rounded, color: AppTheme.primary),
            children: tracks.map<Widget>((t) {
              final trackTitle = t['title']?.toString() ?? '';
              final trackArtist = t['artist']?.toString() ?? '';
              final spotifyUrl = t['url_spotify']?.toString();
              final spotifyUri = t['uri_spotify']?.toString();
              final youtubeUrl = t['url_youtube']?.toString();

              return ListTile(
                dense: true,
                title: Text(trackTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(trackArtist, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF1DB954), size: 24),
                      tooltip: 'Putar di Spotify',
                      onPressed: () => _openUrl(
                        spotifyUrl,
                        uriString: spotifyUri,
                        searchQuery: '$trackTitle $trackArtist',
                        platform: 'spotify',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.music_note_rounded, color: Color(0xFFFF0000), size: 24),
                      tooltip: 'Putar di YouTube',
                      onPressed: () => _openUrl(
                        youtubeUrl,
                        searchQuery: '$trackTitle $trackArtist',
                        platform: 'youtube',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommunitySection() {
    if (_loadingCommunity) {
      return Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
        ),
      );
    }

    if (_communityPlaylists.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Belum ada playlist komunitas.', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    return Column(
      children: _communityPlaylists.map((item) => _buildCommunityCard(item)).toList(),
    );
  }

  Widget _buildCommunityCard(dynamic item) {
    final title = item['title']?.toString() ?? 'Playlist Komunitas';
    final artist = item['artist']?.toString() ?? 'Kurasi Komunitas';
    final spotifyUrl = item['url_spotify']?.toString();
    final youtubeUrl = item['url_youtube']?.toString();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF7E57C2)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(artist, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1DB954), size: 24),
              tooltip: 'Spotify Playlist',
              onPressed: () => _openUrl(
                spotifyUrl,
                searchQuery: title,
                platform: 'spotify',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.music_note_rounded, color: Color(0xFFFF0000), size: 22),
              tooltip: 'YouTube Music',
              onPressed: () => _openUrl(
                youtubeUrl,
                searchQuery: title,
                platform: 'youtube',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPlaylists() {
    if (_loadingMyPlaylists) {
      return Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
        ),
      );
    }

    if (_myPlaylists.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Belum ada playlist pribadi. Tekan + untuk membuat.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: _myPlaylists.map<Widget>((pl) {
        final tracks = (pl['tracks'] as List<dynamic>?) ?? [];
        final playlistId = pl['id'];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            title: Text(
              pl['title']?.toString() ?? 'Playlist',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text('${tracks.length} lagu tersimpan', style: const TextStyle(fontSize: 11)),
            leading: const Icon(Icons.folder_special_rounded, color: AppTheme.primary),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_link_rounded, size: 20),
                  onPressed: () => _addTrackModal(playlistId),
                  tooltip: 'Tambah Lagu',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                  onPressed: () => _deletePlaylist(playlistId),
                  tooltip: 'Hapus Playlist',
                ),
              ],
            ),
            children: tracks.map<Widget>((t) {
              final trackTitle = t['title']?.toString() ?? '';
              final trackArtist = t['artist']?.toString() ?? '';
              final url = t['url']?.toString();

              return ListTile(
                dense: true,
                title: Text(trackTitle),
                subtitle: Text(trackArtist),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
                      onPressed: () => _deleteTrack(t['id']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary),
                      onPressed: () => _openUrl(
                        url,
                        searchQuery: '$trackTitle $trackArtist',
                      ),
                    ),
                  ],
                ),
                onTap: () => _openUrl(
                  url,
                  searchQuery: '$trackTitle $trackArtist',
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}