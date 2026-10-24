import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');

    final int value = int.parse(digitsOnly);
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _loading = true;
  String _selectedCategory = 'Semua';
  List<dynamic> _wishlistItems = [];

  final List<String> _categories = ['Semua', 'Tempat', 'Barang', 'Buku & Film', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    setState(() => _loading = true);
    try {
      final categoryParam = _selectedCategory == 'Semua'
          ? ''
          : '?category=${Uri.encodeComponent(_selectedCategory)}';
      final response = await ApiService.request('GET', 'wishlist$categoryParam');

      if (response.statusCode == 200) {
        final data = ApiService.decode(response);
        setState(() {
          _wishlistItems = (data['wishlist'] as List<dynamic>?) ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _calculateTotalPrice() {
    int total = 0;
    for (var item in _wishlistItems) {
      final category = item['category']?.toString().toLowerCase();
      if (category == 'tempat') continue;

      final priceStr = item['price']?.toString() ?? '';
      final digitsOnly = priceStr.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.isNotEmpty) {
        total += int.parse(digitsOnly);
      }
    }
    return total;
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _openLink(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;
    try {
      final Uri uri = Uri.parse(urlString.trim());
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka link.')),
        );
      }
    }
  }

  Future<void> _confirmDeleteWishlist(dynamic id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Wishlist'),
        content: Text('Yakin mau menghapus "$title" dari wishlist kamu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await ApiService.request('DELETE', 'wishlist/$id');
      if (response.statusCode < 300) {
        _fetchWishlist();
      }
    }
  }

  void _showWishlistModal({Map<String, dynamic>? item}) {
    final formKey = GlobalKey<FormState>();
    final isEdit = item != null;
    String category = item?['category']?.toString() ?? 'Barang';
    String status = item?['status']?.toString().toLowerCase() ?? 'want';

    String initialPrice = '';
    if (item?['price'] != null) {
      final rawDigits = item!['price'].toString().replaceAll(RegExp(r'[^\d]'), '');
      if (rawDigits.isNotEmpty) {
        initialPrice = _formatRupiah(int.parse(rawDigits));
      }
    }

    final titleController = TextEditingController(text: item?['title']?.toString() ?? '');
    final priceController = TextEditingController(text: initialPrice);
    final urlController = TextEditingController(text: item?['url']?.toString() ?? '');
    final imageController = TextEditingController(text: item?['image_url']?.toString() ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isTempat = category.toLowerCase() == 'tempat';

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 10,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Wishlist' : 'Tambah Wishlist Baru',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: ['Tempat', 'Barang', 'Buku & Film', 'Lainnya'].contains(category) ? category : 'Barang',
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: ['Tempat', 'Barang', 'Buku & Film', 'Lainnya']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: isTempat ? 'Nama Tempat *' : 'Judul / Nama Barang *',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return isTempat
                              ? 'Nama tempat wajib diisi!'
                              : 'Judul / nama barang wajib diisi!';
                        }
                        return null;
                      },
                    ),
                    if (!isTempat) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          prefixText: 'Rp ',
                          hintText: '150.000',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: isTempat ? 'Link Google Maps' : 'Link Pembelian / Website',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'Link Foto / Gambar (Opsional)',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: ['want', 'considering', 'purchased'].contains(status) ? status : 'want',
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: isTempat
                          ? const [
                              DropdownMenuItem(value: 'want', child: Text('Want (Ingin Ke Sini)')),
                              DropdownMenuItem(value: 'considering', child: Text('Considering (Dipertimbangkan)')),
                              DropdownMenuItem(value: 'purchased', child: Text('Visited (Pernah Dikunjungi)')),
                            ]
                          : const [
                              DropdownMenuItem(value: 'want', child: Text('Want (Ingin)')),
                              DropdownMenuItem(value: 'considering', child: Text('Considering (Dipertimbangkan)')),
                              DropdownMenuItem(value: 'purchased', child: Text('Purchased (Tercapai / Dibeli)')),
                            ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          String formattedPrice = 'Rp 0';
                          if (!isTempat && priceController.text.trim().isNotEmpty) {
                            formattedPrice = 'Rp ${priceController.text.trim()}';
                          }

                          final body = {
                            'category': category,
                            'title': titleController.text.trim(),
                            'price': formattedPrice,
                            'url': urlController.text.trim(),
                            'image_url': imageController.text.trim(),
                            'status': status,
                          };

                          final response = isEdit
                              ? await ApiService.request('PUT', 'wishlist/${item['id']}', body: body)
                              : await ApiService.request('POST', 'wishlist', body: body);

                          if (mounted) Navigator.pop(ctx);
                          if (response.statusCode < 300) {
                            _fetchWishlist();
                          }
                        },
                        child: Text(isEdit ? 'Perbarui' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tempat':
        return Icons.location_on_rounded;
      case 'barang':
        return Icons.shopping_bag_rounded;
      case 'buku & film':
        return Icons.menu_book_rounded;
      default:
        return Icons.bookmark_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'purchased':
        return Colors.green;
      case 'considering':
        return Colors.orange;
      default:
        return AppTheme.primary;
    }
  }

  String _getStatusLabel(String status, String category) {
    final s = status.toLowerCase();
    final isTempat = category.toLowerCase() == 'tempat';

    if (s == 'purchased') {
      return isTempat ? 'Visited' : 'Purchased';
    } else if (s == 'considering') {
      return 'Considering';
    }
    return 'Want';
  }

  Widget _buildPlatformHeader(String category, String? url) {
    final categoryLower = category.toLowerCase();
    String platformName = category.toUpperCase();
    Color headerColor = AppTheme.primary;
    IconData platformIcon = _getCategoryIcon(category);

    final urlLower = (url ?? '').toLowerCase();
    if (urlLower.contains('shopee') || urlLower.contains('shp.ee')) {
      platformName = 'SHOPEE';
      headerColor = const Color(0xFFEE4D2D);
      platformIcon = Icons.shopping_bag_rounded;
    } else if (urlLower.contains('tokopedia') || urlLower.contains('tokope.ed')) {
      platformName = 'TOKOPEDIA';
      headerColor = const Color(0xFF03AC0E);
      platformIcon = Icons.storefront_rounded;
    } else if (urlLower.contains('tiktok.com')) {
      platformName = 'TIKTOK SHOP';
      headerColor = Colors.black87;
      platformIcon = Icons.video_library_rounded;
    } else if (urlLower.contains('maps') || urlLower.contains('goo.gl') || categoryLower == 'tempat') {
      platformName = 'GOOGLE MAPS';
      headerColor = const Color(0xFF4285F4);
      platformIcon = Icons.map_rounded;
    }

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(platformIcon, size: 38, color: headerColor),
          const SizedBox(height: 6),
          Text(
            platformName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: headerColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotalPrice();
    final selectedLower = _selectedCategory.toLowerCase();

    return Scaffold(
      backgroundColor: AppTheme.current.background,
      appBar: AppBar(title: const Text('My Wishlist')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.current.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          // Masukkan fungsi asli di sini (misal: membuka form tambah goal)
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                        _fetchWishlist();
                      }
                    },
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primary : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          if (selectedLower != 'semua' && selectedLower != 'tempat' && totalPrice > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Estimasi ($_selectedCategory):',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    'Rp ${_formatRupiah(totalPrice)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchWishlist,
                    child: _wishlistItems.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Belum ada wishlist di kategori ini.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _wishlistItems.length,
                            itemBuilder: (context, index) {
                              final item = Map<String, dynamic>.from(_wishlistItems[index] as Map);
                              final imageUrl = item['image_url']?.toString();
                              final category = item['category']?.toString() ?? 'Barang';
                              final categoryLower = category.toLowerCase();
                              final title = item['title']?.toString() ?? '';
                              final price = item['price']?.toString() ?? 'Rp 0';
                              final status = item['status']?.toString() ?? 'Want';
                              final url = item['url']?.toString();

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: (imageUrl != null &&
                                              imageUrl.isNotEmpty &&
                                              !imageUrl.contains('shields.io'))
                                          ? Image.network(
                                              imageUrl,
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => _buildPlatformHeader(category, url),
                                            )
                                          : _buildPlatformHeader(category, url),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(status).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _getStatusLabel(status, category),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusColor(status),
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                                    onPressed: () => _showWishlistModal(item: item),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                                    onPressed: () => _confirmDeleteWishlist(item['id'], title),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            title,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          if (categoryLower != 'tempat' && price != 'Rp 0') ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              price,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ],
                                          if (url != null && url.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () => _openLink(url),
                                                icon: Icon(
                                                  categoryLower == 'tempat' ? Icons.map_rounded : Icons.open_in_new_rounded,
                                                  size: 16,
                                                ),
                                                label: Text(categoryLower == 'tempat' ? 'Buka Google Maps' : 'Lihat Produk'),
                                              ),
                                            )
                                          ]
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}