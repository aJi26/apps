import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart';

import 'api_service.dart';

class GoogleSheetsService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  static Future<bool> ensureDrivePermission() async {
    final scopes = [drive.DriveApi.driveFileScope];
    try {
      bool hasAccess = false;
      try {
        hasAccess = await _googleSignIn.canAccessScopes(scopes);
      } catch (_) {
        hasAccess = false;
      }

      if (!hasAccess) {
        try {
          hasAccess = await _googleSignIn.requestScopes(scopes);
        } catch (_) {
          hasAccess = false;
        }
      }

      return hasAccess || _googleSignIn.currentUser != null;
    } catch (_) {
      return _googleSignIn.currentUser != null;
    }
  }

  static Future<AuthClient?> _getAuthClient() async {
    var googleUser = _googleSignIn.currentUser;
    googleUser ??= await _googleSignIn.signInSilently();
    googleUser ??= await _googleSignIn.signIn();

    if (googleUser == null) return null;
    return await _googleSignIn.authenticatedClient();
  }

  static String _getMonthTitle(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String _getFullMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  static Future<String?> initUserSpreadsheet({
    int? year,
    double targetSavings = 0,
    List<dynamic> existingTransactions = const [],
  }) async {
    await ensureDrivePermission();

    final client = await _getAuthClient();
    if (client == null) {
      throw Exception('Sesi Google Sign-In tidak ditemukan.');
    }

    final sheetsApi = sheets.SheetsApi(client);
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final dateForSheet = DateTime(targetYear, now.month, now.day);
    final sheetTitle = _getMonthTitle(dateForSheet);
    final fileName = 'Her Space - Financial Tracker $targetYear';

    final newSpreadsheet = sheets.Spreadsheet(
      properties: sheets.SpreadsheetProperties(
        title: fileName,
        locale: 'en_US',
      ),
      sheets: [
        sheets.Sheet(
          properties: sheets.SheetProperties(title: sheetTitle),
        ),
      ],
    );

    final created = await sheetsApi.spreadsheets.create(newSpreadsheet);
    final spreadsheetId = created.spreadsheetId;
    final spreadsheetUrl = created.spreadsheetUrl;

    if (spreadsheetId != null) {
      await _setupTemplateForSheet(
        sheetsApi: sheetsApi,
        spreadsheetId: spreadsheetId,
        sheetTitle: sheetTitle,
        date: dateForSheet,
        targetSavings: targetSavings,
        existingTransactions: existingTransactions,
      );

      await ApiService.request('POST', 'finance/spreadsheet-id', body: {
        'spreadsheet_id': spreadsheetId,
        'spreadsheet_url': spreadsheetUrl,
        'year': targetYear,
      });
    }

    return spreadsheetUrl;
  }

  static Future<void> ensureMonthSheetExists({
    required String spreadsheetId,
    required DateTime date,
    double targetSavings = 0,
    List<dynamic> existingTransactions = const [],
  }) async {
    try {
      final client = await _getAuthClient();
      if (client == null) return;

      final sheetsApi = sheets.SheetsApi(client);
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      final sheetTitle = _getMonthTitle(date);

      final exists = spreadsheet.sheets?.any(
            (s) => s.properties?.title == sheetTitle,
          ) ??
          false;

      if (!exists) {
        final addSheetReq = sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(title: sheetTitle),
          ),
        );

        await sheetsApi.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: [addSheetReq]),
          spreadsheetId,
        );

        await _setupTemplateForSheet(
          sheetsApi: sheetsApi,
          spreadsheetId: spreadsheetId,
          sheetTitle: sheetTitle,
          date: date,
          targetSavings: targetSavings,
          existingTransactions: existingTransactions,
        );
      }
    } catch (_) {}
  }

  static Future<void> _setupTemplateForSheet({
    required sheets.SheetsApi sheetsApi,
    required String spreadsheetId,
    required String sheetTitle,
    required DateTime date,
    double targetSavings = 0,
    List<dynamic> existingTransactions = const [],
  }) async {
    final periodText = '${_getFullMonthName(date.month)} ${date.year}';

    // Layout Sheet: Income (A-C), Spacing (D), Expense (E-H)
    final initialData = [
      ['', 'FINANCIAL TRACKER', '', '', 'Total Income', '=C6'],
      ['', '', '', '', 'Total Expense', '=F6'],
      ['', 'Periode', periodText, '', 'Saved Clean', '=F2-F3'],
      ['', 'Target Tabungan', targetSavings, '', 'Selisih Target', '=C5-F4'],
      [
        '',
        'Total Income',
        '=SUM(B9:B1000)',
        '',
        'Total Expense',
        '=SUM(G9:G1000)'
      ],
      ['PEMASUKAN (INCOME)', '', '', '', 'PENGELUARAN (EXPENSE)', '', '', ''],
      ['Tanggal', 'Nominal (Rp)', 'Catatan', '', 'Tanggal', 'Kategori', 'Nominal (Rp)', 'Catatan'],
    ];

    final valueRange = sheets.ValueRange(
      range: "'$sheetTitle'!A2:H8",
      values: initialData,
    );

    await sheetsApi.spreadsheets.values.update(
      valueRange,
      spreadsheetId,
      "'$sheetTitle'!A2:H8",
      valueInputOption: 'USER_ENTERED',
    );

    // Pengaturan Format Sel & Tipe Keyboard pada Google Sheets Mobile
    try {
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      final targetSheet = spreadsheet.sheets?.firstWhere(
        (s) => s.properties?.title == sheetTitle,
        orElse: () => spreadsheet.sheets!.first,
      );
      final sheetIdNum = targetSheet?.properties?.sheetId ?? 0;

      final categories = [
        'Food & Drink',
        'Shopping',
        'Bills & Utilities',
        'Transport',
        'Entertainment',
        'Other'
      ];

      final categoryDropdownRule = sheets.DataValidationRule(
        condition: sheets.BooleanCondition(
          type: 'ONE_OF_LIST',
          values: categories.map((c) => sheets.ConditionValue(userEnteredValue: c)).toList(),
        ),
        showCustomUi: true,
        strict: false,
      );

      final numberFormat = sheets.NumberFormat(type: 'NUMBER', pattern: '#,##0');
      final dateFormat = sheets.NumberFormat(type: 'DATE', pattern: 'yyyy-mm-dd');
      final textFormat = sheets.NumberFormat(type: 'TEXT');

      final requests = [
        // 1. Dropdown Kategori Pengeluaran (Kolom F / Col Index 5)
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetIdNum,
              startRowIndex: 8,
              endRowIndex: 1000,
              startColumnIndex: 5,
              endColumnIndex: 6,
            ),
            cell: sheets.CellData(
              dataValidation: categoryDropdownRule,
              userEnteredFormat: sheets.CellFormat(numberFormat: textFormat),
            ),
            fields: 'dataValidation,userEnteredFormat.numberFormat',
          ),
        ),

        // 2. Format Keyboard Angka: Nominal Income (Kolom B / Col Index 1)
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetIdNum,
              startRowIndex: 8,
              endRowIndex: 1000,
              startColumnIndex: 1,
              endColumnIndex: 2,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(numberFormat: numberFormat),
            ),
            fields: 'userEnteredFormat.numberFormat',
          ),
        ),

        // 3. Format Keyboard Angka: Nominal Expense (Kolom G / Col Index 6)
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetIdNum,
              startRowIndex: 8,
              endRowIndex: 1000,
              startColumnIndex: 6,
              endColumnIndex: 7,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(numberFormat: numberFormat),
            ),
            fields: 'userEnteredFormat.numberFormat',
          ),
        ),

        // 4. Format Tanggal: Tanggal Income (Col Index 0) & Tanggal Expense (Col Index 4)
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetIdNum,
              startRowIndex: 8,
              endRowIndex: 1000,
              startColumnIndex: 0,
              endColumnIndex: 1,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(numberFormat: dateFormat),
            ),
            fields: 'userEnteredFormat.numberFormat',
          ),
        ),
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetIdNum,
              startRowIndex: 8,
              endRowIndex: 1000,
              startColumnIndex: 4,
              endColumnIndex: 5,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(numberFormat: dateFormat),
            ),
            fields: 'userEnteredFormat.numberFormat',
          ),
        ),

        // 5. Format Text Keyboard: Catatan Income (Col Index 2) & Catatan Expense (Col Index 7)
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetIdNum,
              startRowIndex: 8,
              endRowIndex: 1000,
              startColumnIndex: 2,
              endColumnIndex: 3,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(numberFormat: textFormat),
            ),
            fields: 'userEnteredFormat.numberFormat',
          ),
        ),
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetIdNum,
              startRowIndex: 8,
              endRowIndex: 1000,
              startColumnIndex: 7,
              endColumnIndex: 8,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(numberFormat: textFormat),
            ),
            fields: 'userEnteredFormat.numberFormat',
          ),
        ),
      ];

      await sheetsApi.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: requests),
        spreadsheetId,
      );
    } catch (_) {}

    // Pengisian awal transaksi dari aplikasi ke Sheet
    if (existingTransactions.isNotEmpty) {
      final List<List<dynamic>> incomeRows = [];
      final List<List<dynamic>> expenseRows = [];

      for (var tx in existingTransactions) {
        final type = (tx['type'] ?? 'expense').toString().toLowerCase();
        final dateStr = tx['transaction_date']?.toString() ?? '';
        final category = tx['category']?.toString() ?? 'General';
        final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
        final desc = tx['description']?.toString() ?? '';

        if (type == 'income') {
          incomeRows.add([dateStr, amount, desc]);
        } else {
          expenseRows.add([dateStr, category, amount, desc]);
        }
      }

      if (incomeRows.isNotEmpty) {
        await sheetsApi.spreadsheets.values.update(
          sheets.ValueRange(values: incomeRows),
          spreadsheetId,
          "'$sheetTitle'!A9",
          valueInputOption: 'USER_ENTERED',
        );
      }

      if (expenseRows.isNotEmpty) {
        await sheetsApi.spreadsheets.values.update(
          sheets.ValueRange(values: expenseRows),
          spreadsheetId,
          "'$sheetTitle'!E9",
          valueInputOption: 'USER_ENTERED',
        );
      }
    }
  }

  static Future<void> appendTransaction({
    required String? spreadsheetId,
    required int? currentSpreadsheetYear,
    required String date,
    required String type,
    required String category,
    required double amount,
    required String note,
  }) async {
    try {
      final txDate = DateTime.tryParse(date) ?? DateTime.now();
      String? activeSpreadsheetId = spreadsheetId;

      if (activeSpreadsheetId == null || activeSpreadsheetId.isEmpty) return;

      final client = await _getAuthClient();
      if (client == null) return;

      final sheetTitle = _getMonthTitle(txDate);
      final sheetsApi = sheets.SheetsApi(client);

      await ensureMonthSheetExists(
        spreadsheetId: activeSpreadsheetId,
        date: txDate,
      );

      final isIncome = type.toLowerCase() == 'income';
      final range = isIncome ? "'$sheetTitle'!A9:C" : "'$sheetTitle'!E9:H";

      final rowData = isIncome
          ? [
              [date, amount, note]
            ]
          : [
              [date, category, amount, note]
            ];

      await sheetsApi.spreadsheets.values.append(
        sheets.ValueRange(values: rowData),
        activeSpreadsheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
    } catch (_) {}
  }

  // Sinkronisasi 2-Arah dengan Fitur Auto-Backfill Nilai Bawaan Langsung ke Dalam Sheet
  static Future<bool> syncFromSpreadsheet({
    required String spreadsheetId,
    required DateTime date,
  }) async {
    try {
      final client = await _getAuthClient();
      if (client == null) return false;

      final sheetsApi = sheets.SheetsApi(client);
      final sheetTitle = _getMonthTitle(date);

      final List<Map<String, dynamic>> parsedRows = [];
      final List<List<dynamic>> updatedIncomeSheetRows = [];
      final List<List<dynamic>> updatedExpenseSheetRows = [];

      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // 1. Baca & Tulis Ulang Tabel Income (A9:C1000)
      final incomeRes = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        "'$sheetTitle'!A9:C1000",
      );
      if (incomeRes.values != null) {
        for (var row in incomeRes.values!) {
          if (row.isNotEmpty) {
            var dateStr = row[0]?.toString().trim() ?? '';
            final amountVal = row.length > 1
                ? double.tryParse(row[1]?.toString().replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0
                : 0;
            final descStr = row.length > 2 ? row[2]?.toString().trim() ?? '' : '';

            if (amountVal > 0) {
              if (dateStr.isEmpty) dateStr = todayStr;

              parsedRows.add({
                'date': dateStr,
                'type': 'income',
                'category': 'Salary / Income',
                'amount': amountVal,
                'description': descStr,
              });

              updatedIncomeSheetRows.add([dateStr, amountVal, descStr]);
            }
          }
        }
      }

      // 2. Baca & Tulis Ulang Tabel Expense (E9:H1000)
      final expenseRes = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        "'$sheetTitle'!E9:H1000",
      );
      if (expenseRes.values != null) {
        for (var row in expenseRes.values!) {
          if (row.isNotEmpty) {
            var dateStr = row[0]?.toString().trim() ?? '';
            var categoryStr = row.length > 1 ? row[1]?.toString().trim() ?? '' : '';
            final amountVal = row.length > 2
                ? double.tryParse(row[2]?.toString().replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0
                : 0;
            final descStr = row.length > 3 ? row[3]?.toString().trim() ?? '' : '';

            if (amountVal > 0) {
              if (dateStr.isEmpty) dateStr = todayStr;
              if (categoryStr.isEmpty) categoryStr = 'Other';

              parsedRows.add({
                'date': dateStr,
                'type': 'expense',
                'category': categoryStr,
                'amount': amountVal,
                'description': descStr,
              });

              updatedExpenseSheetRows.add([dateStr, categoryStr, amountVal, descStr]);
            }
          }
        }
      }

      // Tuliskan kembali (Backfill) data bersih langsung ke Google Sheets jika ada yang di-auto-fill
      if (updatedIncomeSheetRows.isNotEmpty) {
        await sheetsApi.spreadsheets.values.update(
          sheets.ValueRange(values: updatedIncomeSheetRows),
          spreadsheetId,
          "'$sheetTitle'!A9",
          valueInputOption: 'USER_ENTERED',
        );
      }

      if (updatedExpenseSheetRows.isNotEmpty) {
        await sheetsApi.spreadsheets.values.update(
          sheets.ValueRange(values: updatedExpenseSheetRows),
          spreadsheetId,
          "'$sheetTitle'!E9",
          valueInputOption: 'USER_ENTERED',
        );
      }

      // Kirim data ke backend Laravel
      final syncRes = await ApiService.request('POST', 'finance/sync-from-sheets', body: {
        'month': date.month,
        'year': date.year,
        'rows': parsedRows,
      });

      return syncRes.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}