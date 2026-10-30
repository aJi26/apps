<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DailyCheckin;
use App\Models\ActivityLog;
use App\Models\Portrait;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class DailyPotretController extends Controller
{
    private const TIMEZONE = 'Asia/Jakarta';

    // Penentu "Hari" baru dimulai jam 07:00 Pagi
    private function getLogicalToday(): string
    {
        $now = Carbon::now(self::TIMEZONE);
        if ($now->format('H:i') < '07:00') {
            return $now->subDay()->toDateString();
        }
        return $now->toDateString();
    }

    public function checkTodayStatus(Request $request)
    {
        $logicalToday = $this->getLogicalToday();
        
        $checkin = DailyCheckin::where('user_id', $request->user()->id)
            ->where('checkin_date', $logicalToday)
            ->first();
            
        $portrait = $checkin
            ? Portrait::where('checkin_id', $checkin->id)->first()
            : null;

        return response()->json([
            'date' => $logicalToday,
            'completed' => $portrait !== null,
            'checkin_id' => $portrait ? $checkin->id : null,
            'portrait' => $portrait ? [
                'id' => $portrait->id,
                'date' => $portrait->created_at->format('d M Y'),
                'time' => $portrait->created_at->format('H:i'),
                'image_url' => str_starts_with($portrait->path, 'http') ? $portrait->path : url("/api/portraits/{$portrait->id}/image"),
            ] : null,
        ]);
    }

    public function gallery(Request $request)
    {
        $portraits = Portrait::whereHas('checkin', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })
        ->with('checkin')
        ->latest()
        ->get()
        ->map(function ($portrait) {
            return [
                'id' => $portrait->id,
                'date' => $portrait->created_at->format('d M Y'),
                'time' => $portrait->created_at->format('H:i'),
                'image_url' => str_starts_with($portrait->path, 'http') ? $portrait->path : url("/api/portraits/{$portrait->id}/image"),
            ];
        });

        return response()->json([
            'portraits' => $portraits,
        ]);
    }

    public function getImage(Request $request, Portrait $portrait)
    {
        abort_unless($portrait->checkin?->user_id === $request->user()->id, 403);

        if (str_starts_with($portrait->path, 'http://') || str_starts_with($portrait->path, 'https://')) {
            return redirect($portrait->path);
        }

        abort_unless(Storage::disk('local')->exists($portrait->path), 404);

        return Storage::disk('local')->response($portrait->path);
    }

    public function uploadPotret(Request $request)
    {
        $validated = $request->validate([
            'photo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:10240'],
        ]);

        $user = $request->user();
        $logicalToday = $this->getLogicalToday();
        $photo = $validated['photo'];

        // UBAH: Gunakan cloudinary()->upload() agar aman dari error null URL
        $path = cloudinary()->upload($photo->getRealPath(), [
            'folder' => 'herspace/portraits'
        ])->getSecurePath();

        if (! is_string($path) || $path === '') {
            throw new RuntimeException('Foto Potret gagal disimpan ke Cloudinary.');
        }

        try {
            $result = DB::transaction(function () use ($user, $logicalToday, $path, $photo) {
                User::whereKey($user->id)->lockForUpdate()->firstOrFail();

                $checkin = DailyCheckin::firstOrCreate([
                    'user_id' => $user->id,
                    'checkin_date' => $logicalToday,
                ]);

                $existingPortrait = Portrait::where('checkin_id', $checkin->id)->first();

                if ($existingPortrait) {
                    if (str_starts_with($existingPortrait->path, 'http')) {
                        $this->deleteFromCloudinary($existingPortrait->path);
                    } elseif (Storage::disk('local')->exists($existingPortrait->path)) {
                        Storage::disk('local')->delete($existingPortrait->path);
                    }

                    $existingPortrait->update([
                        'path' => $path,
                        'original_name' => $photo->getClientOriginalName(),
                    ]);

                    return ['portrait' => $existingPortrait, 'created' => false];
                }

                $portrait = Portrait::create([
                    'checkin_id' => $checkin->id,
                    'path' => $path,
                    'original_name' => $photo->getClientOriginalName(),
                ]);

                ActivityLog::create([
                    'user_id' => $user->id,
                    'action' => 'completed daily Potret',
                    'type' => 'Check-in',
                    'subject_type' => Portrait::class,
                    'subject_id' => $portrait->id,
                ]);

                return ['portrait' => $portrait, 'created' => true];
            });

            return response()->json([
                'message' => 'Potret berhasil disimpan.',
                'completed' => true,
                'portrait' => [
                    'id' => $result['portrait']->id,
                    'image_url' => $result['portrait']->path,
                ],
            ], 201);
        } catch (\Throwable $e) {
            $this->deleteFromCloudinary($path);
            throw $e;
        }
    }

    // TAMBAHKAN HELPER INI DI DALAM KELAS UNTUK MENGHAPUS FILE CLOUDINARY
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