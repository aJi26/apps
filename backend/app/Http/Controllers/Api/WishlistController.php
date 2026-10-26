<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Wishlist;
use Illuminate\Http\Request;

class WishlistController extends Controller
{
    private function getImageUrl($customImageUrl, $url, $title = '', $category = 'Barang')
    {
        if (!empty($customImageUrl) && filter_var($customImageUrl, FILTER_VALIDATE_URL)) {
            return $customImageUrl;
        }
        return null;
    }

    public function index(Request $request)
    {
        $status = $request->query('status');
        $category = $request->query('category');

        $items = $request->user()->wishlists()
            ->when($status && strtolower($status) !== 'semua' && strtolower($status) !== 'all', function ($query) use ($status) {
                $st = strtolower($status);
                // Jika mencari visited / purchased, cocokkan kedua status tersebut untuk kompatibilitas
                if (in_array($st, ['visited', 'purchased'])) {
                    $query->whereIn(\DB::raw('LOWER(status)'), ['visited', 'purchased']);
                } else {
                    $query->whereRaw('LOWER(status) = ?', [$st]);
                }
            })
            ->when($category && strtolower($category) !== 'semua', function ($query) use ($category) {
                $query->whereRaw('LOWER(category) = ?', [strtolower($category)]);
            })
            ->latest()
            ->get()
            ->map(function ($item) {
                // Utamakan kolom price, fallback ke description
                $priceVal = $item->price ?? $item->description ?? 'Rp 0';
                if (is_numeric($priceVal)) {
                    $priceVal = 'Rp ' . number_format((float)$priceVal, 0, ',', '.');
                }

                return [
                    'id' => $item->id,
                    'category' => $item->category ?? 'Barang',
                    'title' => $item->title,
                    'price' => $priceVal,
                    'url' => $item->url,
                    'image_url' => $item->image_url,
                    'status' => strtolower($item->status),
                    'created_at' => $item->created_at->format('d M Y'),
                ];
            });

        return response()->json(['wishlist' => $items]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category' => ['nullable', 'string', 'max:50'],
            'title' => ['required', 'string', 'max:255'],
            'price' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:want,considering,purchased,visited,Want,Considering,Purchased,Visited'],
            'url' => ['nullable', 'string', 'max:1000'],
            'image_url' => ['nullable', 'string', 'max:1000'],
        ]);

        $category = $validated['category'] ?? 'Barang';
        $title = $validated['title'];
        $url = $validated['url'] ?? null;
        $price = $validated['price'] ?? 'Rp 0';
        
        $imageUrl = $this->getImageUrl($validated['image_url'] ?? null, $url, $title, $category);

        // Ekstrak angka murni untuk disimpan di kolom price
        $numericPrice = (float) preg_replace('/[^\d]/', '', (string) $price);

        $item = $request->user()->wishlists()->create([
            'category' => $category,
            'title' => $title,
            'price' => $numericPrice,
            'description' => $price, // Disimpan di description juga sebagai fallback
            'status' => strtolower($validated['status'] ?? 'want'),
            'url' => $url,
            'image_url' => $imageUrl,
        ]);

        ActivityLog::create([
            'user_id' => $request->user()->id,
            'action' => 'added to wishlist: ' . $item->title,
            'type' => 'Other',
            'subject_type' => Wishlist::class,
            'subject_id' => $item->id,
        ]);

        return response()->json([
            'message' => 'Item wishlist berhasil ditambahkan.',
            'item' => $item,
        ], 201);
    }

    public function update(Request $request, Wishlist $wishlist)
    {
        abort_unless($wishlist->user_id === $request->user()->id, 403);

        $validated = $request->validate([
            'category' => ['sometimes', 'string', 'max:50'],
            'title' => ['sometimes', 'string', 'max:255'],
            'price' => ['nullable', 'string', 'max:100'],
            'status' => ['sometimes', 'in:want,considering,purchased,visited,Want,Considering,Purchased,Visited'],
            'url' => ['nullable', 'string', 'max:1000'],
            'image_url' => ['nullable', 'string', 'max:1000'],
        ]);

        if (isset($validated['price'])) {
            $numericPrice = (float) preg_replace('/[^\d]/', '', (string) $validated['price']);
            $validated['price'] = $numericPrice;
            $validated['description'] = $request->price;
        }

        if (isset($validated['status'])) {
            $validated['status'] = strtolower($validated['status']);
        }

        $category = $validated['category'] ?? $wishlist->category;
        $title = $validated['title'] ?? $wishlist->title;
        $url = array_key_exists('url', $validated) ? $validated['url'] : $wishlist->url;
        $customImage = array_key_exists('image_url', $validated) ? $validated['image_url'] : $wishlist->image_url;

        $validated['image_url'] = $this->getImageUrl($customImage, $url, $title, $category);

        $wishlist->update($validated);

        return response()->json([
            'message' => 'Item wishlist berhasil diperbarui.',
            'item' => $wishlist,
        ]);
    }

    public function destroy(Request $request, Wishlist $wishlist)
    {
        abort_unless($wishlist->user_id === $request->user()->id, 403);
        $wishlist->delete();

        return response()->json(['message' => 'Item wishlist berhasil dihapus.']);
    }
}