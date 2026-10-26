<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserPreference;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MusicController extends Controller
{
    // Helper untuk mengambil mood terbaru user menggunakan Model UserPreference
    private function getUserMood($user): string
    {
        $mood = UserPreference::where('user_id', $user->id)
            ->where('preference_key', 'today_mood')
            ->latest('id')
            ->value('preference_value');

        if (!empty($mood)) {
            return trim($mood);
        }

        return trim($user->profile?->current_mood ?? 'Calm');
    }

    // Mesin Pencari Musik iTunes dengan Caching
    private function fetchLiveTracks($searchTerm, $limit = 25)
    {
        $cacheKey = 'itunes_search_' . md5($searchTerm . '_' . $limit);

        return Cache::remember($cacheKey, 43200, function () use ($searchTerm, $limit) {
            try {
                $response = Http::withoutVerifying()
                    ->timeout(5)
                    ->get('https://itunes.apple.com/search', [
                        'term' => $searchTerm,
                        'entity' => 'song',
                        'limit' => $limit,
                    ]);

                if ($response->failed()) return [];

                $results = $response->json()['results'] ?? [];

                return collect($results)->map(function ($track) {
                    $title = $track['trackName'] ?? 'Unknown Track';
                    $artist = $track['artistName'] ?? 'Unknown Artist';
                    $collection = $track['collectionName'] ?? '';
                    $queryClean = urlencode("$title $artist");

                    return [
                        'title' => $title,
                        'artist' => $artist,
                        'collection' => $collection,
                        'url_youtube' => "https://music.youtube.com/search?q={$queryClean}",
                        'url_spotify' => "https://open.spotify.com/search/{$queryClean}",
                        'uri_spotify' => null,
                    ];
                })->values()->toArray();

            } catch (\Exception $e) {
                Log::error('iTunes Fetch Exception: ' . $e->getMessage());
                return [];
            }
        });
    }

    // 1. Rekomendasi Utama (Banner)
    public function dailyRecommendation(Request $request)
    {
        $user = $request->user();
        $currentMood = $this->getUserMood($user);

        // Pencocokan string mood dari Flutter ('Amazing', 'Good', 'Calm', 'Tired', 'Not great')
        $query = match (strtolower($currentMood)) {
            'amazing', 'good', 'happy' => 'top global pop happy hits',
            'tired', 'not great', 'anxious', 'sad' => 'top sad pop ballads acoustic',
            'calm', 'peaceful' => 'chill soft pop rnb hits',
            default => 'chill soft pop rnb hits',
        };

        $tracks = $this->fetchLiveTracks($query, 30);
        $formatted = !empty($tracks) ? $tracks[array_rand($tracks)] : null;

        if ($formatted) {
            $formatted['genre'] = strtoupper($currentMood);
        } else {
            $queryClean = urlencode("Die With A Smile Lady Gaga Bruno Mars");
            $formatted = [
                'title' => 'Die With A Smile',
                'artist' => 'Lady Gaga, Bruno Mars',
                'genre' => strtoupper($currentMood),
                'url_youtube' => "https://music.youtube.com/search?q={$queryClean}",
                'url_spotify' => "https://open.spotify.com/search/{$queryClean}",
                'uri_spotify' => null,
            ];
        }

        return response()->json([
            'mood' => $currentMood,
            'recommendation' => $formatted,
        ]);
    }

    // 2. Explore Genres (Dinamis per Mood)
    public function categories(Request $request)
    {
        $user = $request->user();
        $rawMood = $this->getUserMood($user);
        $currentMood = strtolower($rawMood);

        $moodCategories = match ($currentMood) {
            'amazing', 'good', 'happy' => [
                'Mainstream Pop Hits' => 'top pop hits',
                'Upbeat Rap & Hip-Hop' => 'top hip hop rap hits',
                'Viral Hipdut & Party' => 'hiphop dangdut viral',
                'Energetic K-Pop' => 'top kpop energetic hits',
                'Feel-Good R&B' => 'feel good rnb pop',
            ],
            'tired', 'not great', 'anxious', 'sad' => [
                'Sad Pop & Ballads' => 'top sad pop ballads',
                'Melodic Rap & Emo Beats' => 'melodic rap emo hip hop',
                'Galau Indo & Hipdut' => 'galau hipdut pop jawa',
                'Melancholic Indie' => 'sad indie acoustic hits',
                'Slow R&B' => 'slow rnb soul hits',
            ],
            default => [
                'Soft Pop & Acoustic' => 'soft acoustic pop hits',
                'Chill R&B & Soul' => 'chill rnb soul',
                'Indie Santai & Akustik' => 'indie pop akustik indonesia',
                'Acoustic Hits' => 'top acoustic hits',
                'Chill Global Vibes' => 'chill pop vibes',
            ],
        };

        $result = [];

        foreach ($moodCategories as $categoryName => $searchQuery) {
            $tracks = $this->fetchLiveTracks($searchQuery, 25);

            if (!empty($tracks)) {
                $uniqueTracks = collect($tracks)->unique('title')->values();
                $selectedTracks = $uniqueTracks->shuffle()->take(5)->toArray();
            } else {
                $queryClean = urlencode($categoryName);
                $selectedTracks = [
                    [
                        'title' => "{$categoryName} Mix",
                        'artist' => 'Top Artists',
                        'url_youtube' => "https://music.youtube.com/search?q={$queryClean}",
                        'url_spotify' => "https://open.spotify.com/search/{$queryClean}",
                        'uri_spotify' => null,
                    ]
                ];
            }

            $result[] = ['genre' => $categoryName, 'tracks' => $selectedTracks];
        }

        return response()->json(['categories' => $result]);
    }

    // 3. Community Playlists
    public function communityPlaylists(Request $request)
    {
        $user = $request->user();
        $currentMood = strtolower($this->getUserMood($user));

        $modifiers = ['Vault', 'Mix', 'Sessions', 'Vibes', 'Archive', 'Collection', 'Essentials', 'Radio'];
        $randomModifier = $modifiers[array_rand($modifiers)];

        $baseQuery = match ($currentMood) {
            'amazing', 'good', 'happy' => 'upbeat party viral hits',
            'tired', 'not great', 'anxious', 'sad' => 'sad acoustic galau hits',
            default => 'chill late night lofi',
        };

        $liveData = $this->fetchLiveTracks("{$baseQuery} {$randomModifier}", 20);

        if (!empty($liveData)) {
            $uniqueData = collect($liveData)->unique('artist')->shuffle()->take(4);

            $playlists = $uniqueData->map(function ($item) use ($randomModifier) {
                $playlistTitle = !empty($item['collection']) 
                    ? $item['collection'] . ' (' . $randomModifier . ')'
                    : $item['artist'] . ' & Friends ' . $randomModifier;

                $curatorName = 'Komunitas ' . $item['artist'];

                $qYt = urlencode("{$playlistTitle} playlist");
                $qSpotify = urlencode($playlistTitle);

                return [
                    'title' => $playlistTitle,
                    'artist' => $curatorName,
                    'url_youtube' => "https://music.youtube.com/search?q={$qYt}",
                    'url_spotify' => "https://open.spotify.com/search/{$qSpotify}/playlists",
                ];
            })->values()->toArray();
        } else {
            $playlists = [
                [
                    'title' => 'Late Night Vibe Mix',
                    'artist' => 'Komunitas NightDrive',
                    'url_youtube' => 'https://music.youtube.com/search?q=Late+night+drive+playlist',
                    'url_spotify' => 'https://open.spotify.com/search/Late%20night%20drive/playlists',
                ]
            ];
        }

        return response()->json(['playlists' => $playlists]);
    }

    // 4. My Playlists
    public function myPlaylists(Request $request)
    {
        $playlists = DB::table('user_playlists')
            ->where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        foreach ($playlists as $playlist) {
            $playlist->tracks = DB::table('user_playlist_tracks')
                ->where('user_playlist_id', $playlist->id)
                ->get();
        }

        return response()->json(['my_playlists' => $playlists]);
    }

    public function storePlaylist(Request $request)
    {
        $request->validate(['title' => 'required|string|max:100']);

        $id = DB::table('user_playlists')->insertGetId([
            'user_id' => $request->user()->id,
            'title' => $request->title,
            'cover_color' => '#E8F5E9',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Playlist created successfully', 'id' => $id], 201);
    }

    public function addTrack(Request $request, $id)
    {
        $request->validate([
            'title' => 'required|string|max:150',
            'url' => 'required|string',
        ]);

        $trackId = DB::table('user_playlist_tracks')->insertGetId([
            'user_playlist_id' => $id,
            'title' => $request->title,
            'artist' => $request->artist ?? 'Custom Track',
            'url' => $request->url,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Track added successfully', 'id' => $trackId], 201);
    }

    public function deletePlaylist(Request $request, $id)
    {
        DB::table('user_playlists')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->delete();

        return response()->json(['message' => 'Playlist deleted']);
    }

    public function deleteTrack($trackId)
    {
        DB::table('user_playlist_tracks')->where('id', $trackId)->delete();
        return response()->json(['message' => 'Track removed']);
    }
}