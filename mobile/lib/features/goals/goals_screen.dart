import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<dynamic> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.request('GET', 'goals');
      if (response.statusCode < 300) {
        final data = ApiService.decode(response);
        setState(() => _goals = data['goals'] as List<dynamic>? ?? []);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addOrEditGoal([Map<String, dynamic>? item]) async {
    final title = TextEditingController(text: item?['title']?.toString() ?? '');
    final desc = TextEditingController(text: item?['description']?.toString() ?? '');
    int progress = (item?['progress'] as num?)?.round() ?? 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Tambah Target' : 'Edit Target'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul Target')),
              const SizedBox(height: 12),
              TextField(controller: desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan Motivasi')),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Progress: $progress%'),
                  Expanded(
                    child: Slider(
                      value: progress.toDouble(),
                      max: 100,
                      divisions: 20,
                      onChanged: (val) => setDialogState(() => progress = val.round()),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (saved == true) {
      final body = {
        'title': title.text.trim(),
        'description': desc.text.trim(),
        'progress': progress,
      };
      final response = await ApiService.request(
        item == null ? 'POST' : 'PUT',
        item == null ? 'goals' : 'goals/${item['id']}',
        body: body,
      );
      if (response.statusCode < 300) _loadGoals();
    }
  }

  Future<void> _deleteGoal(int id) async {
    final response = await ApiService.request('DELETE', 'goals/$id');
    if (response.statusCode < 300) _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.current.background,
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.current.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          // Masukkan fungsi asli di sini (misal: membuka form tambah goal)
        },
        child: const Icon(Icons.add),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = _goals[idx];
                final progress = ((item['progress'] ?? 0) as num) / 100;

                return Card(
                  child: ListTile(
                    title: Text(item['title']?.toString() ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['description'] != null) Text(item['description'].toString()),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppTheme.sageSoft,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (act) {
                        if (act == 'edit') _addOrEditGoal(item);
                        if (act == 'delete') _deleteGoal(item['id']);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}