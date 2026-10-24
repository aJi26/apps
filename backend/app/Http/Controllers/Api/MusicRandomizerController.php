<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class MusicRandomizerController extends Controller
{
    public function playlists(Request $request)
    {
        $category = $request->query('category', 'For You');

        $allPlaylists = [
            [
                'id' => 1,
                'title' => 'Midnight Thoughts',
                'subtitle' => 'Playlist • 50 songs',
                'category' => 'Chill',
                'cover_color' => '#E8ECE9',
                'icon' => '🌙',
                'is_liked' => true,
            ],
            [
                'id' => 2,
                'title' => 'Japan Trips',
                'subtitle' => 'Playlist • 42 songs',
                'category' => 'Happy',
                'cover_color' => '#FEEAE6',
                'icon' => '🌸',
                'is_liked' => true,
            ],
            [
                'id' => 3,
                'title' => 'Focus Mode',
                'subtitle' => 'Playlist • 54 songs',
                'category' => 'Focus',
                'cover_color' => '#FAF7F2',
                'icon' => '☕',
                'is_liked' => true,
            ],
            [
                'id' => 4,
                'title' => 'My Favorites',
                'subtitle' => 'Playlist • 120 songs',
                'category' => 'For You',
                'cover_color' => '#E8ECE9',
                'icon' => '✨',
                'is_liked' => true,
            ],
        ];

        return response()->json([
            'playlists' => $allPlaylists,
        ]);
    }

    public function randomize(Request $request)
    {
        $ideas = [
            [
                'title' => "Today's little thing",
                'text' => 'Go somewhere you have never been and buy yourself a warm drink. ♡',
                'tag' => 'Adventure',
            ],
            [
                'title' => 'Mindful Moment',
                'text' => 'Put your phone away for 30 minutes, open the window, and listen to the birds. 🌿',
                'tag' => 'Peace',
            ],
            [
                'title' => 'Sweet Treat',
                'text' => 'Bake or buy your favorite pastry and enjoy every single bite without guilt. 🥐',
                'tag' => 'Self-Care',
            ],
            [
                'title' => 'Creative Spark',
                'text' => 'Take 3 photos of ordinary things today from an angle you never tried before. 📷',
                'tag' => 'Creativity',
            ],
            [
                'title' => 'Heart Warmth',
                'text' => 'Send a short message to someone you appreciate telling them they made a difference. 💌',
                'tag' => 'Connection',
            ],
        ];

        $random = $ideas[array_rand($ideas)];

        return response()->json([
            'idea' => $random,
        ]);
    }
}

