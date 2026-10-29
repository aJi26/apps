<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\PhotoDump;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class PhotoDumpController extends Controller
{
    public function index(Request $request)
    {
        $dumps = PhotoDump::where('user_id', $request->user()->id)
            ->latest()
            ->get()
            ->map(function ($dump) {
                return [
                    'id' => $dump->id,
                    'caption' => $dump->caption,
                    'date' => $dump->created_at->format('d M Y'),
                    'time' => $dump->created_at->format('H:i'),
                    'image_url' => str_starts_with($dump->path, 'http') 
                        ? $dump->path 
                        : url("/api/photo-dumps/{$dump->id}/image"),
                ];
            });

        return response()->json(['photo_dumps' => $dumps]);
    }

    public function upload(Request $request)
    {
        $validated = $request->validate([
            'photo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:10240'],
            'caption' => ['nullable', 'string', 'max:255'],
        ]);

        $photo = $validated['photo'];
        $user = $request->user();

        // 1. Simpan ke storage lokal (mengikuti pola DailyPotret)
        $path = $photo->store('photo_dumps', 'local');

        if (! is_string($path) || $path === '') {
            throw new RuntimeException('Gagal menyimpan foto ke storage.');
        }

        try {
            // 2. Simpan ke database PhotoDump
            $dump = PhotoDump::create([
                'user_id' => $user->id,
                'path' => $path,
                'caption' => $request->input('caption'),
                'original_name' => $photo->getClientOriginalName(),
            ]);

            // 3. Catat ke Activity Log agar otomatis masuk ke riwayat aktivitas admin
            ActivityLog::create([
                'user_id' => $user->id,
                'action' => 'Mengunggah foto baru ke Photo Dump',
                'type' => 'Photo Dump',
                'subject_type' => PhotoDump::class,
                'subject_id' => $dump->id,
            ]);

            return response()->json([
                'message' => 'Photo dump berhasil diunggah.',
                'photo_dump' => [
                    'id' => $dump->id,
                    'caption' => $dump->caption,
                    'image_url' => url("/api/photo-dumps/{$dump->id}/image"),
                ],
            ], 201);

        } catch (\Throwable $e) {
            // Jika database gagal, hapus file fisik yang terlanjur tersimpan
            Storage::disk('local')->delete($path);
            throw $e;
        }
    }

    public function getImage(Request $request, PhotoDump $photoDump)
    {
        abort_unless($photoDump->user_id === $request->user()->id, 403);

        if (str_starts_with($photoDump->path, 'http://') || str_starts_with($photoDump->path, 'https://')) {
            return redirect($photoDump->path);
        }

        abort_unless(Storage::disk('local')->exists($photoDump->path), 404);

        return Storage::disk('local')->response($photoDump->path);
    }

    public function destroy(Request $request, PhotoDump $photoDump)
    {
        abort_unless($photoDump->user_id === $request->user()->id, 403);

        if (Storage::disk('local')->exists($photoDump->path)) {
            Storage::disk('local')->delete($photoDump->path);
        }

        $photoDump->delete();

        return response()->json(['message' => 'Photo dump berhasil dihapus.']);
    }
}