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

    public function checkTodayStatus(Request $request)
    {
        $today = Carbon::now(self::TIMEZONE)->toDateString();
        $checkin = DailyCheckin::where('user_id', $request->user()->id)
            ->where('checkin_date', $today)
            ->first();
        $portrait = $checkin
            ? Portrait::where('checkin_id', $checkin->id)->first()
            : null;

        return response()->json([
            'date' => $today,
            'completed' => $portrait !== null,
            'checkin_id' => $portrait ? $checkin->id : null,
        ]);
    }

    public function uploadPotret(Request $request)
    {
        $validated = $request->validate([
            'photo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:10240'],
        ]);

        $user = $request->user();
        $today = Carbon::now(self::TIMEZONE)->toDateString();
        $existingPortrait = DailyCheckin::where('user_id', $user->id)
            ->where('checkin_date', $today)
            ->first();

        if ($existingPortrait) {
            $existingPortrait = Portrait::where('checkin_id', $existingPortrait->id)->first();

            if ($existingPortrait) {
                return response()->json([
                    'message' => 'Potret hari ini sudah selesai.',
                    'completed' => true,
                    'portrait' => $existingPortrait,
                ]);
            }
        }

        $photo = $validated['photo'];
        $path = $photo->store('portraits', 'local');

        if (! is_string($path) || $path === '') {
            throw new RuntimeException('Foto Potret gagal disimpan ke private storage.');
        }

        $keepFile = false;

        try {
            $result = DB::transaction(function () use ($user, $today, $path, $photo) {
                User::whereKey($user->id)->lockForUpdate()->firstOrFail();

                $checkin = DailyCheckin::where('user_id', $user->id)
                    ->where('checkin_date', $today)
                    ->lockForUpdate()
                    ->first();

                if ($checkin) {
                    $portrait = Portrait::where('checkin_id', $checkin->id)->first();

                    if ($portrait) {
                        return ['portrait' => $portrait, 'created' => false];
                    }
                } else {
                    $checkin = DailyCheckin::create([
                        'user_id' => $user->id,
                        'checkin_date' => $today,
                    ]);
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

            $keepFile = $result['created'];

            return response()->json([
                'message' => $result['created']
                    ? 'Potret berhasil disimpan.'
                    : 'Potret hari ini sudah selesai.',
                'completed' => true,
                'portrait' => $result['portrait'],
            ], $result['created'] ? 201 : 200);
        } finally {
            if (! $keepFile) {
                Storage::disk('local')->delete($path);
            }
        }
    }
}
