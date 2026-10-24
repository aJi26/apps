import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class FeatureScreen extends StatefulWidget {
  final String type;
  const FeatureScreen({super.key, required this.type});
  @override
  State<FeatureScreen> createState() => _FeatureScreenState();
}

class _FeatureScreenState extends State<FeatureScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String _category = 'All', _search = '';
  Object? _randomKey = Object();
  String get _endpoint => switch (widget.type) {
    'Notes' => 'notes',
    'Goals' => 'goals',
    'Wishlist' => 'wishlist',
    'Music' => 'music/playlists',
    'Mood history' => 'potret/gallery',
    _ => 'notes',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.request(
        'GET',
        _endpoint,
        query: widget.type == 'Notes'
            ? {'category': _category, 'search': _search}
            : null,
      );
      if (response.statusCode >= 300) {
        throw StateError('Could not load ${widget.type.toLowerCase()}.');
      }
      final data = ApiService.decode(response);
      _items = switch (widget.type) {
        'Notes' => data['notes'] as List<dynamic>,
        'Goals' => data['goals'] as List<dynamic>,
        'Wishlist' => data['wishlist'] as List<dynamic>,
        'Music' => data['playlists'] as List<dynamic>,
        'Mood history' => data['portraits'] as List<dynamic>,
        _ => [],
      };
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addOrEdit([Map<String, dynamic>? item]) async {
    final title = TextEditingController(text: item?['title']?.toString() ?? '');
    final detail = TextEditingController(
      text: widget.type == 'Notes'
          ? (item?['content']?.toString() ?? '')
          : widget.type == 'Wishlist'
          ? (item?['price']?.toString() ?? '')
          : (item?['description']?.toString() ?? ''),
    );
    final location = TextEditingController(
      text: item?['url']?.toString() ?? '',
    );
    var category =
        item?['category']?.toString() ??
        (_category == 'All' ? 'Personal' : _category);
    var status = item?['status']?.toString().toLowerCase() ?? 'want';
    var progress = (item?['progress'] as num?)?.round() ?? 0;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(
            item == null
                ? 'Add ${widget.type == 'Notes'
                      ? 'note'
                      : widget.type == 'Goals'
                      ? 'goal'
                      : 'wishlist item'}'
                : 'Edit ${widget.type.toLowerCase()}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                if (widget.type == 'Notes') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: detail,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Your note'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Personal',
                        child: Text('Personal'),
                      ),
                      DropdownMenuItem(value: 'Ideas', child: Text('Ideas')),
                      DropdownMenuItem(value: 'To Do', child: Text('To Do')),
                    ],
                    onChanged: (value) =>
                        refresh(() => category = value ?? 'Personal'),
                  ),
                ],
                if (widget.type == 'Goals') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: detail,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'A note to encourage yourself',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Progress'),
                      Expanded(
                        child: Slider(
                          value: progress.toDouble(),
                          max: 100,
                          divisions: 20,
                          label: '$progress%',
                          onChanged: (value) =>
                              refresh(() => progress = value.round()),
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.type == 'Wishlist') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: detail,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Price (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'Location or link',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'want', child: Text('Want')),
                      DropdownMenuItem(
                        value: 'considering',
                        child: Text('Considering'),
                      ),
                      DropdownMenuItem(
                        value: 'purchased',
                        child: Text('Purchased'),
                      ),
                    ],
                    onChanged: (value) =>
                        refresh(() => status = value ?? 'want'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      final body = switch (widget.type) {
        'Notes' => {
          'title': title.text.trim(),
          'content': detail.text.trim(),
          'category': category,
        },
        'Goals' => {
          'title': title.text.trim(),
          'description': detail.text.trim(),
          'progress': progress,
        },
        _ => {
          'title': title.text.trim(),
          'price': detail.text.trim(),
          'url': location.text.trim(),
          'status': status,
        },
      };
      final response = await ApiService.request(
        item == null ? 'POST' : 'PUT',
        item == null ? _endpoint : '$_endpoint/${item['id']}',
        body: body,
      );
      if (response.statusCode >= 300 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiService.decode(response)['message']?.toString() ??
                  'Could not save.',
            ),
          ),
        );
      } else {
        await _load();
      }
    }
    title.dispose();
    detail.dispose();
    location.dispose();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final response = await ApiService.request(
      'DELETE',
      '$_endpoint/${item['id']}',
    );
    if (response.statusCode < 300) {
      await _load();
    } else if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this item.')),
      );
  }

  Future<void> _openMap(String query) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps on this device.')),
      );
    }
  }

  Future<void> _openMusic(String title, String service) async {
    final encoded = Uri.encodeComponent(title);
    final uri = service == 'Spotify'
        ? Uri.parse('https://open.spotify.com/search/$encoded')
        : Uri.parse('https://music.youtube.com/search?q=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the music app.')),
      );
    }
  }

  Future<void> _viewSnapshot(Map<String, dynamic> item) async {
    final imageUrl = item['image_url']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) return;
    final token = await ApiService.getToken();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  imageUrl,
                  headers: {'Authorization': 'Bearer ${token ?? ''}'},
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Could not load this snapshot.'),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.type == 'Randomizer') return _randomizer();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(widget.type)),
      floatingActionButton: ['Notes', 'Goals', 'Wishlist'].contains(widget.type)
          ? FloatingActionButton(
              onPressed: () => _addOrEdit(),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          if (widget.type == 'Notes') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search notes',
                ),
                onChanged: (value) {
                  _search = value;
                  _load();
                },
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final value in ['All', 'Personal', 'Ideas', 'To Do'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(value),
                        selected: _category == value,
                        onSelected: (_) {
                          _category = value;
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: _items.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _itemCard(
                      Map<String, dynamic>.from(_items[index] as Map),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    if (widget.type == 'Music') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.blush,
                    child: Icon(Icons.headphones, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          item['subtitle']?.toString() ?? '',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openMusic(item['title'].toString(), 'Spotify'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Spotify'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openMusic(item['title'].toString(), 'YouTube Music'),
                      icon: const Icon(Icons.music_note),
                      label: const Text('YouTube Music'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (widget.type == 'Mood history') {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.photo_outlined, color: AppTheme.primary),
          title: Text(item['date']?.toString() ?? 'Daily snapshot'),
          subtitle: Text(item['time']?.toString() ?? ''),
          trailing: const Icon(
            Icons.check_circle_outline,
            color: AppTheme.primary,
          ),
          onTap: () => _viewSnapshot(item),
        ),
      );
    }
    final subtitle = widget.type == 'Notes'
        ? item['content']?.toString() ?? ''
        : widget.type == 'Wishlist'
        ? '${item['price'] ?? ''} · ${item['status'] ?? ''}'
        : item['description']?.toString() ?? '';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        title: Text(item['title']?.toString() ?? 'Untitled'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (widget.type == 'Goals') ...[
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: ((item['progress'] ?? 0) as num) / 100,
                  minHeight: 7,
                  backgroundColor: AppTheme.sageSoft,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ],
        ),
        trailing:
            widget.type == 'Wishlist' &&
                (item['url']?.toString().isNotEmpty ?? false)
            ? IconButton(
                onPressed: () => _openMap(item['url'].toString()),
                icon: const Icon(Icons.map_outlined),
                tooltip: 'Open in Maps',
              )
            : PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') {
                    _addOrEdit(item);
                  } else {
                    _delete(item);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
      ),
    );
  }

  Widget _randomizer() => FutureBuilder<http.Response>(
    key: ValueKey(_randomKey),
    future: ApiService.request('GET', 'randomizer'),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || snapshot.data!.statusCode >= 300) {
        return Scaffold(
          appBar: AppBar(title: const Text('Randomizer')),
          body: Center(
            child: ElevatedButton(
              onPressed: () => setState(() => _randomKey = Object()),
              child: const Text('Try again'),
            ),
          ),
        );
      }
      final idea =
          ApiService.decode(snapshot.data!)['idea'] as Map<String, dynamic>;
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Daily randomizer')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 44)),
                    Text(
                      idea['title']?.toString() ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      idea['text']?.toString() ?? '',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: () => setState(() => _randomKey = Object()),
                      child: const Text('Give me another idea'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _empty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.spa_outlined, color: AppTheme.primary, size: 42),
          const SizedBox(height: 12),
          Text(
            'Nothing here just yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
          const SizedBox(height: 6),
          Text(
            widget.type == 'Mood history'
                ? 'Your snapshots will live here.'
                : 'Tap + when you’re ready to add something.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    ),
  );
}
