import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class PhotoDumpScreen extends StatefulWidget {
  const PhotoDumpScreen({super.key});

  @override
  State<PhotoDumpScreen> createState() => _PhotoDumpScreenState();
}

class _PhotoDumpScreenState extends State<PhotoDumpScreen> {
  List<dynamic> _dumps = [];
  bool _loading = true;
  bool _uploading = false;
  String _token = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchPhotoDumps();
  }

  Future<void> _fetchPhotoDumps() async {
    try {
      setState(() => _loading = true);
      _token = await ApiService.getToken() ?? '';
      
      final response = await ApiService.request('GET', 'photo-dumps');
      if (response.statusCode == 200) {
        final data = ApiService.decode(response);
        setState(() {
          _dumps = data['photo_dumps'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 1. DENGAN KOMPRESI OTOMATIS (Mencegah Error 422)
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 3000, // Resolusi tetap besar
        maxHeight: 3000,
        imageQuality: 95, // Kualitas hampir tidak dikurangi
      );

      if (image == null) return;

      setState(() => _uploading = true);

      final token = await ApiService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/photo-dumps/upload'),
      );
      
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo dump uploaded successfully!')),
          );
        }
        _fetchPhotoDumps();
      } else {
        throw Exception('Server Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // 2. DIALOG FULLSCREEN PREVIEW & HAPUS FOTO
  void _showImageDetailDialog(Map<String, dynamic> dump) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // FITUR ZOOM IN / ZOOM OUT (InteractiveViewer)
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  dump['image_url'],
                  headers: _token.isNotEmpty ? {'Authorization': 'Bearer $_token'} : null,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 64),
                      SizedBox(height: 8),
                      Text('Failed to load image', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
            
            // TOMBOL CLOSE (KIRI ATAS)
            Positioned(
              top: 40,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ),

            // TOMBOL HAPUS (KANAN ATAS)
            Positioned(
              top: 40,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _confirmDelete(dump['id']);
                  },
                ),
              ),
            ),

            // INFORMASI TANGGAL (BAWAH)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Text(
                'Uploaded on ${dump['date'] ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. PROSES HAPUS FOTO
  Future<void> _confirmDelete(int dumpId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo Dump'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.request('DELETE', 'photo-dumps/$dumpId');
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo dump deleted.')),
            );
          }
          _fetchPhotoDumps();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  void _showImageSourceDialog() {
    final primaryColor = AppTheme.current.primary;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.current.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create Photo Dump 📸',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: primaryColor),
                title: const Text('Import from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: primaryColor),
                title: const Text('Take a New Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.current.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Dump Gallery'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _uploading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Uploading your photo...'),
                    ],
                  ),
                )
              : _dumps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📷', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          const Text(
                            'No photo dumps yet.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button below to share your moments.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPhotoDumps,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: _dumps.length,
                        itemBuilder: (context, index) {
                          final item = _dumps[index];
                          return GestureDetector(
                            onTap: () => _showImageDetailDialog(item),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    item['image_url'],
                                    headers: _token.isNotEmpty ? {'Authorization': 'Bearer $_token'} : null,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppTheme.sageSoft,
                                      child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.6),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        item['date'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceDialog,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Add Photo', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}