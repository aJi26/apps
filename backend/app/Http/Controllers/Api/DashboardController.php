<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DailyCheckin;
use App\Models\Portrait;
use App\Models\UserPreference;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    private const TIMEZONE = 'Asia/Jakarta';

    public function index(Request $request)
    {
        $user = $request->user();
        $today = Carbon::now(self::TIMEZONE)->toDateString();

        // Checkin status
        $checkin = DailyCheckin::where('user_id', $user->id)
            ->where('checkin_date', $today)
            ->first();
        $hasPotret = $checkin
            ? Portrait::where('checkin_id', $checkin->id)->exists()
            : false;

        // Current mood
        $mood = UserPreference::where('user_id', $user->id)
            ->where('preference_key', 'today_mood')
            ->value('preference_value') ?? 'Calm';

        // Quotes list for Today's little thing
        $quotes = [
            "Take a little break today. You've been doing your best. ♡",
            "Small progress is still progress. Be proud of yourself today. ✨",
            "Drink some water, take a deep breath, and smile. 🌿",
            "Your journey is uniquely yours. Embrace every step. ♡",
            "Remember to do something kind for yourself today. 🌸",
        ];
        $todayQuote = $quotes[abs(crc32($today)) % count($quotes)];

        return response()->json([
            'greeting' => $this->getGreeting() . ', ' . explode(' ', $user->name)[0] . '! ☀️',
            'date' => Carbon::now(self::TIMEZONE)->format('l, d F Y'),
            'today_quote' => $todayQuote,
            'current_mood' => $mood,
            'summary' => [
                'active_goals' => $user->goals()->where('status', 'active')->count(),
                'wishlist_items' => $user->wishlists()->count(),
                'notes_count' => $user->notes()->count(),
            ],
            'potret_completed' => $hasPotret,
        ]);
    }

    public function setMood(Request $request)
    {
        $validated = $request->validate([
            'mood' => ['required', 'string', 'max:50'],
        ]);

        UserPreference::updateOrCreate(
            ['user_id' => $request->user()->id, 'preference_key' => 'today_mood'],
            ['preference_value' => $validated['mood']]
        );

        return response()->json([
            'message' => 'Mood berhasil disimpan.',
            'mood' => $validated['mood'],
        ]);
    }

    private function getGreeting(): string
    {
        $hour = Carbon::now(self::TIMEZONE)->hour;
        if ($hour < 12) return 'Good morning';
        if ($hour < 17) return 'Good afternoon';
        return 'Good evening';
    }
}

