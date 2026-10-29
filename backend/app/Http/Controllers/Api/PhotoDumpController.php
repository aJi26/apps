<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\PhotoDump;
use CloudinaryLabs\CloudinaryLaravel\Facades\Cloudinary;
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
                    'image_url' => $dump->path, // Langsung gunakan path URL Cloudinary
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

        // PILIHAN 1: Menggunakan Helper Cloudinary bawaan package (paling sering berhasil)
        $uploadedFileUrl = cloudinary()->upload($photo->getRealPath(), [
            'folder' => 'photo_dumps'
        ])->getSecureUrl();

        /* 
           CATATAN: Jika helper di atas masih error, kamu bisa aktifkan PILIHAN 2 
           dengan memanfaatkan Laravel Storage standar jika disk Cloudinary sudah terdaftar di filesystems.php:
           
           $path = $photo->store('photo_dumps', 'cloudinary');
           $uploadedFileUrl = Storage::disk('cloudinary')->url($path);
        */

        if (!$uploadedFileUrl) {
            throw new RuntimeException('Gagal mengunggah foto ke Cloudinary.');
        }

        // Simpan ke Database Photo Dump
        $dump = PhotoDump::create([
            'user_id' => $user->id,
            'path' => $uploadedFileUrl,
            'caption' => $request->input('caption'),
            'original_name' => $photo->getClientOriginalName(),
        ]);

        // Rekam Aktivitas ke Activity Log
        ActivityLog::create([
            'user_id' => $user->id,
            'type' => 'Photo Dump',
            'action' => 'Mengunggah foto baru ke Photo Dump',
        ]);

        return response()->json([
            'message' => 'Photo dump berhasil diunggah.',
            'photo_dump' => [
                'id' => $dump->id,
                'caption' => $dump->caption,
                'image_url' => $dump->path,
            ],
        ], 201);
    }

    public function getImage(Request $request, PhotoDump $photoDump)
    {
        abort_unless($photoDump->user_id === $request->user()->id, 403);

        // Karena sudah Cloudinary, langsung redirect ke URL-nya
        return redirect($photoDump->path);
    }

    public function destroy(Request $request, PhotoDump $photoDump)
    {
        abort_unless($photoDump->user_id === $request->user()->id, 403);

        // Hapus data dari database (file di Cloudinary bisa dikelola via dashboard Cloudinary)
        $photoDump->delete();

        return response()->json(['message' => 'Photo dump berhasil dihapus.']);
    }
}