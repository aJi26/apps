<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Finance;
use App\Models\FinanceTarget;
use App\Models\UserSpreadsheet;
use App\Models\Wishlist;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class FinanceController extends Controller
{
    public function getSummary(Request $request)
    {
        $user = $request->user();
        $month = (int) $request->query('month', Carbon::now()->month);
        $year = (int) $request->query('year', Carbon::now()->year);

        $startOfMonth = Carbon::createFromDate($year, $month, 1)->startOfMonth()->startOfDay();
        $endOfMonth = Carbon::createFromDate($year, $month, 1)->endOfMonth()->endOfDay();

        $parsePrice = function ($item) {
            $attrs = method_exists($item, 'toArray') ? $item->toArray() : (array) $item;
            foreach (['price', 'numeric_price', 'target_price', 'amount', 'harga', 'cost', 'nominal'] as $key) {
                if (isset($attrs[$key]) && $attrs[$key] !== null && $attrs[$key] !== '') {
                    $raw = $attrs[$key];
                    if (is_numeric($raw)) {
                        $val = (float) $raw;
                        if ($val > 0) return $val;
                    }
                    if (is_string($raw)) {
                        $clean = trim($raw);
                        if (preg_match('/^\d+\.\d{2}$/', $clean)) {
                            return (float) $clean;
                        }
                        $digitsOnly = preg_replace('/[^\d]/', '', $clean);
                        if ($digitsOnly !== '') {
                            $val = (float) $digitsOnly;
                            if ($val > 0) return $val;
                        }
                    }
                }
            }
            return 0;
        };

        // 1. Total Income & Expense bulan ini
        $income = Finance::where('user_id', $user->id)
            ->where('type', 'income')
            ->whereBetween('transaction_date', [$startOfMonth->toDateString(), $endOfMonth->toDateString()])
            ->sum('amount');

        $expense = Finance::where('user_id', $user->id)
            ->where('type', 'expense')
            ->whereBetween('transaction_date', [$startOfMonth->toDateString(), $endOfMonth->toDateString()])
            ->sum('amount');

        // 2. Total Wishlist Terbeli Bulan Ini
        $purchasedWishlistTotal = Wishlist::where('user_id', $user->id)
            ->whereIn(DB::raw('LOWER(status)'), ['purchased', 'visited', 'completed', 'done', 'terbeli'])
            ->whereBetween('updated_at', [$startOfMonth->toDateTimeString(), $endOfMonth->toDateTimeString()])
            ->get()
            ->sum($parsePrice);

        $saved = ($income - $expense) - $purchasedWishlistTotal;

        // 3. Target Tabungan Bulan Ini
        $targetObj = FinanceTarget::where('user_id', $user->id)
            ->where('month', $month)
            ->where('year', $year)
            ->first();
        $targetAmount = $targetObj ? $targetObj->target_amount : 0;

        // 4. Active Wishlist (Mengambil seluruh wishlist aktif)
        $activeWishlist = Wishlist::where('user_id', $user->id)
            ->where(function ($query) {
                $query->whereNull('status')
                      ->orWhere('status', '')
                      ->orWhereNotIn(DB::raw('LOWER(status)'), ['purchased', 'visited', 'completed', 'done', 'terbeli']);
            })
            ->get()
            ->map(function ($item) use ($parsePrice) {
                $item->numeric_price = $parsePrice($item);
                return $item;
            })
            ->values();

        $activeWishlistTotal = $activeWishlist->sum('numeric_price');

        // 5. Riwayat Transaksi Bulan Ini
        $allTransactions = Finance::where('user_id', $user->id)
            ->whereBetween('transaction_date', [$startOfMonth->toDateString(), $endOfMonth->toDateString()])
            ->orderBy('transaction_date', 'desc')
            ->orderBy('id', 'desc')
            ->get();

        $totalTransactionsCount = $allTransactions->count();
        $recentTransactions = $allTransactions->take(5)->values();

        // 6. Ambil Google Spreadsheet khusus milik User & Tahun ini (Tanpa fallback .env)
        $spreadsheet = UserSpreadsheet::where('user_id', $user->id)
            ->where('year', $year)
            ->first();

        $monthNames = [
            1 => 'Januari', 2 => 'Februari', 3 => 'Maret', 4 => 'April',
            5 => 'Mei', 6 => 'Juni', 7 => 'Juli', 8 => 'Agustus',
            9 => 'September', 10 => 'Oktober', 11 => 'November', 12 => 'Desember'
        ];

        return response()->json([
            'summary' => [
                'income' => (float) $income,
                'expense' => (float) $expense,
                'saved' => (float) $saved,
                'purchased_wishlist_deduction' => (float) $purchasedWishlistTotal,
                'target_saved' => (float) $targetAmount,
                'active_wishlist_total' => (float) $activeWishlistTotal,
                'spreadsheet_id' => $spreadsheet?->spreadsheet_id,
                'spreadsheet_url' => $spreadsheet?->spreadsheet_url,
                'spreadsheet_year' => $spreadsheet?->year ?? $year,
                'total_transactions_count' => $totalTransactionsCount,
                'period_label' => $monthNames[(int)$month] . ' ' . $year,
            ],
            'active_wishlist' => $activeWishlist,
            'transactions' => $recentTransactions,
            'all_transactions' => $allTransactions,
        ]);
    }

    public function storeTransaction(Request $request)
    {
        $request->validate([
            'type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:1',
            'category' => 'nullable|string',
            'description' => 'nullable|string',
            'transaction_date' => 'required|date',
        ]);

        $user = $request->user();

        $finance = Finance::create([
            'user_id' => $user->id,
            'type' => $request->type,
            'amount' => $request->amount,
            'category' => $request->category ?? 'General',
            'description' => $request->description,
            'transaction_date' => $request->transaction_date,
        ]);

        return response()->json([
            'message' => 'Transaction saved successfully!',
            'data' => $finance,
        ], 201);
    }

    public function updateTransaction(Request $request, Finance $finance)
    {
        abort_unless($finance->user_id === $request->user()->id, 403);

        $request->validate([
            'type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:1',
            'category' => 'nullable|string',
            'description' => 'nullable|string',
            'transaction_date' => 'required|date',
        ]);

        $finance->update([
            'type' => $request->type,
            'amount' => $request->amount,
            'category' => $request->category ?? 'General',
            'description' => $request->description,
            'transaction_date' => $request->transaction_date,
        ]);

        return response()->json([
            'message' => 'Transaction updated successfully!',
            'data' => $finance,
        ]);
    }

    public function destroyTransaction(Request $request, Finance $finance)
    {
        abort_unless($finance->user_id === $request->user()->id, 403);
        $finance->delete();

        return response()->json(['message' => 'Transaction deleted successfully!']);
    }

    public function setTarget(Request $request)
    {
        $request->validate([
            'month' => 'required|integer|between:1,12',
            'year' => 'required|integer',
            'target_amount' => 'required|numeric|min:0',
        ]);

        $target = FinanceTarget::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'month' => $request->month,
                'year' => $request->year,
            ],
            ['target_amount' => $request->target_amount]
        );

        return response()->json([
            'message' => 'Target tabungan berhasil diperbarui!',
            'data' => $target,
        ]);
    }

    public function syncFromSheets(Request $request)
    {
        $validated = $request->validate([
            'month' => ['required', 'integer', 'between:1,12'],
            'year' => ['required', 'integer'],
            'rows' => ['required', 'array'],
            'rows.*.date' => ['required', 'date'],
            'rows.*.type' => ['required', 'string'],
            'rows.*.category' => ['required', 'string'],
            'rows.*.amount' => ['required', 'numeric'],
            'rows.*.description' => ['nullable', 'string'],
        ]);

        $user = $request->user();
        $month = $validated['month'];
        $year = $validated['year'];

        $startOfMonth = Carbon::createFromDate($year, $month, 1)->startOfMonth()->toDateString();
        $endOfMonth = Carbon::createFromDate($year, $month, 1)->endOfMonth()->toDateString();

        Finance::where('user_id', $user->id)
            ->whereBetween('transaction_date', [$startOfMonth, $endOfMonth])
            ->delete();

        foreach ($validated['rows'] as $row) {
            Finance::create([
                'user_id' => $user->id,
                'type' => strtolower($row['type']),
                'category' => $row['category'],
                'amount' => $row['amount'],
                'description' => $row['description'] ?? '',
                'transaction_date' => $row['date'],
            ]);
        }

        return response()->json([
            'message' => 'Sinkronisasi dari Google Sheets berhasil!',
        ]);
    }

    public function storeSpreadsheetId(Request $request)
    {
        $validated = $request->validate([
            'spreadsheet_id' => ['required', 'string'],
            'spreadsheet_url' => ['required', 'string'],
            'year' => ['required', 'integer'],
        ]);

        UserSpreadsheet::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'year' => $validated['year'],
            ],
            [
                'spreadsheet_id' => $validated['spreadsheet_id'],
                'spreadsheet_url' => $validated['spreadsheet_url'],
            ]
        );

        return response()->json(['message' => 'Spreadsheet ID updated successfully.']);
    }
}