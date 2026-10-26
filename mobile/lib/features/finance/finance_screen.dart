import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/api_service.dart';
import '../../core/services/google_sheets_service.dart';
import '../../core/theme/app_theme.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
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

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool _loading = true;
  bool _isSyncing = false;
  Map<String, dynamic> _summary = {};
  List<dynamic> _transactions = [];
  List<dynamic> _allTransactions = [];
  List<dynamic> _activeWishlist = [];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  num _parseNum(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val;
    final digitsOnly = val.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return num.tryParse(digitsOnly) ?? 0;
  }

  Future<void> _loadFinanceData() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.request('GET', 'finance/summary');
      if (response.statusCode < 300) {
        final data = ApiService.decode(response);
        setState(() {
          _summary = data['summary'] as Map<String, dynamic>? ?? {};
          _transactions = data['transactions'] as List<dynamic>? ?? [];
          _allTransactions = data['all_transactions'] as List<dynamic>? ?? [];
          _activeWishlist = data['active_wishlist'] as List<dynamic>? ?? [];
        });
      } else {
        debugPrint('Error finance summary: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception load finance: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSyncFromSheets() async {
    final spreadsheetId = _summary['spreadsheet_id']?.toString();
    if (spreadsheetId == null || spreadsheetId.isEmpty) {
      _loadFinanceData();
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final success = await GoogleSheetsService.syncFromSpreadsheet(
        spreadsheetId: spreadsheetId,
        date: DateTime.now(),
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disinkronkan dari Google Sheets!')),
        );
      }
    } catch (_) {
    } finally {
      await _loadFinanceData();
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  String _formatRupiah(num number) {
    final int val = number.round();
    final formatted = val.abs().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '${val < 0 ? '- ' : ''}Rp $formatted';
  }

  Future<void> _openGoogleSheets({bool forceRecreate = false}) async {
    String? urlString = _summary['spreadsheet_url']?.toString();

    // Jika dipaksa buat ulang ATAU urlString belum ada
    if (forceRecreate || urlString == null || urlString.trim().isEmpty) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menyiapkan file Google Sheets baru di Drive kamu...'),
            ),
          );
        }

        final targetSavings = _parseNum(_summary['target_saved']).toDouble();
        urlString = await GoogleSheetsService.initUserSpreadsheet(
          targetSavings: targetSavings,
          existingTransactions: _allTransactions,
        );

        if (urlString != null && mounted) {
          await _loadFinanceData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File Google Sheets baru berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuat Google Sheets: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    if (urlString != null && urlString.trim().isNotEmpty) {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka link Google Sheets.')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteTransaction(dynamic id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response =
          await ApiService.request('DELETE', 'finance/transaction/$id');
      if (mounted && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully.')),
        );
        _loadFinanceData();
      }
    }
  }

  void _showTransactionModal({Map<String, dynamic>? transaction}) {
    final formKey = GlobalKey<FormState>();
    final isEdit = transaction != null;
    bool isSubmitting = false;

    String type = transaction?['type']?.toString().toLowerCase() ?? 'expense';
    String category = transaction?['category']?.toString() ?? 'Food & Drink';

    String initialAmount = '';
    if (transaction?['amount'] != null) {
      final num val = _parseNum(transaction!['amount']);
      if (val > 0) initialAmount = _formatRupiah(val).replaceAll('Rp ', '');
    }

    final amountController = TextEditingController(text: initialAmount);
    final descController = TextEditingController(
      text: transaction?['description']?.toString() ?? '',
    );

    final categories = [
      'Food & Drink',
      'Shopping',
      'Bills & Utilities',
      'Transport',
      'Entertainment',
      'Salary / Income',
      'Other'
    ];

    if (!categories.contains(category)) {
      category = 'Other';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 10,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Transaction' : 'Add Transaction',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Expense')),
                          selected: type == 'expense',
                          selectedColor: Colors.redAccent.withValues(alpha: 0.2),
                          onSelected: isSubmitting
                              ? null
                              : (_) => setModalState(() => type = 'expense'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Income')),
                          selected: type == 'income',
                          selectedColor: Colors.green.withValues(alpha: 0.2),
                          onSelected: isSubmitting
                              ? null
                              : (_) => setModalState(() => type = 'income'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount (Rp)',
                      prefixText: 'Rp ',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required field' : null,
                  ),
                  if (type == 'expense') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Note / Description',
                      hintText: 'Ex: Monthly salary / Coffee',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;

                              setModalState(() => isSubmitting = true);

                              final digitsOnly = amountController.text
                                  .replaceAll(RegExp(r'[^\d]'), '');
                              final double parsedAmount =
                                  double.tryParse(digitsOnly) ?? 0;
                              final String txDate = transaction?['transaction_date'] ??
                                  DateTime.now().toIso8601String().split('T')[0];
                              final String selectedCategory =
                                  type == 'expense' ? category : 'Income';
                              final String note = descController.text.trim();

                              final body = {
                                'type': type,
                                'amount': parsedAmount,
                                'category': selectedCategory,
                                'description': note,
                                'transaction_date': txDate,
                              };

                              final response = isEdit
                                  ? await ApiService.request(
                                      'PUT',
                                      'finance/transaction/${transaction['id']}',
                                      body: body,
                                    )
                                  : await ApiService.request(
                                      'POST',
                                      'finance/transaction',
                                      body: body,
                                    );

                              if (mounted) {
                                if (response.statusCode < 300) {
                                  final spreadsheetId =
                                      _summary['spreadsheet_id']?.toString();
                                  final spreadsheetYear =
                                      _summary['spreadsheet_year'] != null
                                          ? int.tryParse(
                                              _summary['spreadsheet_year']
                                                  .toString(),
                                            )
                                          : null;

                                  if (!isEdit) {
                                    GoogleSheetsService.appendTransaction(
                                      spreadsheetId: spreadsheetId,
                                      currentSpreadsheetYear: spreadsheetYear,
                                      date: txDate,
                                      type: type,
                                      category: selectedCategory,
                                      amount: parsedAmount,
                                      note: note,
                                    );
                                  }

                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEdit
                                            ? 'Transaction updated successfully!'
                                            : 'Transaction saved successfully!',
                                      ),
                                    ),
                                  );
                                  _loadFinanceData();
                                } else {
                                  setModalState(() => isSubmitting = false);
                                  final errData = ApiService.decode(response);
                                  final errMsg = errData['message'] ??
                                      'Failed to save transaction.';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed: $errMsg'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Transaction' : 'Save Transaction',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAllTransactionsModal() {
    String searchQuery = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _allTransactions.where((tx) {
            final desc = (tx['description'] ?? '').toString().toLowerCase();
            final cat = (tx['category'] ?? '').toString().toLowerCase();
            final q = searchQuery.toLowerCase();
            return desc.contains(q) || cat.contains(q);
          }).toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction History (${_summary['period_label'] ?? 'This Month'})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (v) => setModalState(() => searchQuery = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions found.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final tx = filtered[idx];
                              return _buildTransactionCard(tx, isFromModal: true);
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSetTargetModal() {
    final controller = TextEditingController(
      text: _summary['target_saved'] != null &&
              _parseNum(_summary['target_saved']) > 0
          ? _formatRupiah(_parseNum(_summary['target_saved']))
              .replaceAll('Rp ', '')
          : '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Savings Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Target Rp',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final digitsOnly = controller.text.replaceAll(RegExp(r'[^\d]'), '');
              final now = DateTime.now();
              final body = {
                'month': now.month,
                'year': now.year,
                'target_amount': double.tryParse(digitsOnly) ?? 0,
              };

              final response =
                  await ApiService.request('POST', 'finance/target', body: body);
              if (mounted) Navigator.pop(ctx);
              if (response.statusCode < 300) _loadFinanceData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, {bool isFromModal = false}) {
    final isIncome = tx['type'] == 'income';
    final num amount = _parseNum(tx['amount']);
    final title =
        tx['description'] != null && tx['description'].toString().isNotEmpty
            ? tx['description'].toString()
            : tx['category'].toString();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 4),
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.redAccent,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${tx['transaction_date']} • ${tx['category'] ?? '-'}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'} ${_formatRupiah(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: Colors.grey,
              ),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (isFromModal) Navigator.pop(context);
                if (value == 'edit') {
                  _showTransactionModal(transaction: tx);
                } else if (value == 'delete') {
                  _confirmDeleteTransaction(tx['id'], title);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(fontSize: 13, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.current.primary;
    final sageSoftColor = AppTheme.current.sageSoft;

    final income = _parseNum(_summary['income']);
    final expense = _parseNum(_summary['expense']);
    final saved = _parseNum(_summary['saved']);
    final targetSaved = _parseNum(_summary['target_saved']);
    final wishlistTotal = _parseNum(_summary['active_wishlist_total']);
    final periodLabel = _summary['period_label']?.toString() ?? '';
    final totalCount = (_summary['total_transactions_count'] as num?) ?? 0;

    double progress =
        targetSaved > 0 ? (saved / targetSaved).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.current.background,
      appBar: AppBar(
        title: const Text('My Finance'),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: _isSyncing ? null : _handleSyncFromSheets,
            tooltip: 'Sync 2-Way from Sheets',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showTransactionModal(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleSyncFromSheets,
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80,
                ),
                children: [
                  if (periodLabel.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Period: $periodLabel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  InkWell(
                    onTap: () => _openGoogleSheets(forceRecreate: false),
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Buat Ulang Sheet?'),
                          content: const Text(
                            'Gunakan fitur ini jika file Google Sheets lama Anda terhapus atau berada di sampah.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openGoogleSheets(forceRecreate: true);
                              },
                              child: const Text('Buat Sheet Baru'),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.table_chart_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Open Google Sheets',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                Text(
                                  'Tekan tahan untuk membuat ulang file jika terhapus',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: Color(0xFF1B5E20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildSummaryCard(
                        'Income',
                        _formatRupiah(income),
                        Icons.arrow_downward_rounded,
                        const Color(0xFFE8F5E9),
                        Colors.green.shade700,
                      ),
                      _buildSummaryCard(
                        'Expenses',
                        _formatRupiah(expense),
                        Icons.arrow_upward_rounded,
                        const Color(0xFFFFEBEE),
                        Colors.red.shade700,
                      ),
                      _buildSummaryCard(
                        'Saved Clean',
                        _formatRupiah(saved),
                        Icons.account_balance_wallet_rounded,
                        sageSoftColor,
                        primaryColor,
                      ),
                      _buildSummaryCard(
                        'Active Wishlist',
                        _formatRupiah(wishlistTotal),
                        Icons.card_giftcard_rounded,
                        const Color(0xFFFCE4EC),
                        const Color(0xFFEC407A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Monthly Savings Target',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Material(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: _showSetTargetModal,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: primaryColor.withValues(alpha: 0.4),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        targetSaved > 0
                                            ? Icons.edit_rounded
                                            : Icons.add_rounded,
                                        size: 13,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        targetSaved > 0
                                            ? 'Edit Target'
                                            : 'Set Target',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: sageSoftColor,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Collected: ${_formatRupiah(saved)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              'Target: ${_formatRupiah(targetSaved)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_activeWishlist.isNotEmpty) ...[
                    Text(
                      'Monthly Dream Wishlist',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _activeWishlist.length,
                        itemBuilder: (ctx, idx) {
                          final item = _activeWishlist[idx];
                          final num itemPrice =
                              _parseNum(item['numeric_price'] ?? item['price']);

                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item['title']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatRupiah(itemPrice),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (totalCount > 5)
                        InkWell(
                          onTap: _showAllTransactionsModal,
                          child: Text(
                            'View All ($totalCount)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No transactions yet this month.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final tx = _transactions[idx];
                        return _buildTransactionCard(tx, isFromModal: false);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}