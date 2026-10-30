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

        // BYPASS BUG: Gunakan uploadApi()->upload() langsung
        $uploaded = cloudinary()->uploadApi()->upload($photo->getRealPath(), [
            'folder' => 'herspace/photo_dumps'
        ]);

        $path = $uploaded['secure_url'] ?? null;

        if (! is_string($path) || $path === '') {
            throw new RuntimeException('Gagal menyimpan foto ke Cloudinary.');
        }

        try {
            $dump = PhotoDump::create([
                'user_id' => $user->id,
                'path' => $path,
                'caption' => $request->input('caption'),
                'original_name' => $photo->getClientOriginalName(),
            ]);

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
                    'image_url' => $dump->path,
                ],
            ], 201);

        } catch (\Throwable $e) {
            $this->deleteFromCloudinary($path);
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

        // UBAH: Logika penghapusan file
        if (str_starts_with($photoDump->path, 'http')) {
            $this->deleteFromCloudinary($photoDump->path);
        } elseif (Storage::disk('local')->exists($photoDump->path)) {
            Storage::disk('local')->delete($photoDump->path);
        }

        $photoDump->delete();

        return response()->json(['message' => 'Photo dump berhasil dihapus.']);
    }

    // TAMBAHKAN HELPER INI
    private function deleteFromCloudinary($url) {
        if (!str_starts_with($url, 'http')) return;
        $parts = explode('/upload/', $url);
        if (isset($parts[1])) {
            $publicIdWithExt = preg_replace('/^v\d+\//', '', $parts[1]);
            $publicId = pathinfo($publicIdWithExt, PATHINFO_DIRNAME) . '/' . pathinfo($publicIdWithExt, PATHINFO_FILENAME);
            cloudinary()->destroy($publicId);
        }
    }
}