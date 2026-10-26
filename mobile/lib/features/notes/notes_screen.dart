import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<dynamic> _notes = [];
  bool _loading = true;
  String _category = 'All';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.request(
        'GET',
        'notes',
        query: {'category': _category, 'search': _search},
      );
      if (response.statusCode < 300) {
        final data = ApiService.decode(response);
        setState(() => _notes = data['notes'] as List<dynamic>? ?? []);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<T?> _showAnimatedDialog<T>(Widget child) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) => child,
      transitionBuilder: (ctx, anim1, anim2, childWidget) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue.clamp(0.0, 1.0),
          child: Opacity(
            opacity: anim1.value,
            child: childWidget,
          ),
        );
      },
    );
  }

  Future<void> _addOrEditNote([Map<String, dynamic>? item]) async {
    final title = TextEditingController(text: item?['title']?.toString() ?? '');
    final content = TextEditingController(text: item?['content']?.toString() ?? '');
    var category = item?['category']?.toString() ?? (_category == 'All' ? 'Personal' : _category);

    final saved = await _showAnimatedDialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(item == null ? 'Add Note' : 'Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: content, maxLines: 4, decoration: const InputDecoration(labelText: 'Note Content')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: ['Personal', 'Ideas', 'To Do'].contains(category) ? category : 'Personal',
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                DropdownMenuItem(value: 'Ideas', child: Text('Ideas')),
                DropdownMenuItem(value: 'To Do', child: Text('To Do')),
              ],
              onChanged: (val) => category = val ?? 'Personal',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved == true) {
      final body = {
        'title': title.text.trim(),
        'content': content.text.trim(),
        'category': category,
      };
      final response = await ApiService.request(
        item == null ? 'POST' : 'PUT',
        item == null ? 'notes' : 'notes/${item['id']}',
        body: body,
      );
      if (response.statusCode < 300) _loadNotes();
    }
  }

  Future<void> _deleteNote(int id) async {
    final response = await ApiService.request('DELETE', 'notes/$id');
    if (response.statusCode < 300) _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.current.background,
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.current.primary,
        foregroundColor: Colors.white,
        onPressed: () => _addOrEditNote(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search notes...'),
              onChanged: (val) {
                _search = val;
                _loadNotes();
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['All', 'Personal', 'Ideas', 'To Do'].map((cat) {
                final selected = _category == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _category = cat);
                      _loadNotes();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = _notes[idx];
                      return Card(
                        child: ListTile(
                          title: Text(item['title']?.toString() ?? 'Tanpa Judul'),
                          subtitle: Text(item['content']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: PopupMenuButton<String>(
                            onSelected: (act) {
                              if (act == 'edit') _addOrEditNote(item);
                              if (act == 'delete') _deleteNote(item['id']);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}