<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MusicSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('music_tracks')->truncate();

        DB::table('music_tracks')->insert([
            // --- REKOMENDASI LAGU (HITS KEKINIAN) ---
            [
                'title' => 'Espresso',
                'artist' => 'Sabrina Carpenter',
                'genre' => 'Pop',
                'mood' => 'Amazing, Happy',
                'url_spotify' => 'https://open.spotify.com/search/Espresso%20Sabrina%20Carpenter',
                'url_youtube' => 'https://music.youtube.com/search?q=Espresso+Sabrina+Carpenter',
                'is_community_playlist' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Satu Bulan',
                'artist' => 'Bernadya',
                'genre' => 'Indie',
                'mood' => 'Sad, Anxious',
                'url_spotify' => 'https://open.spotify.com/search/Satu%20Bulan%20Bernadya',
                'url_youtube' => 'https://music.youtube.com/search?q=Satu+Bulan+Bernadya',
                'is_community_playlist' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Sial',
                'artist' => 'Mahalini',
                'genre' => 'Pop',
                'mood' => 'Sad, Anxious',
                'url_spotify' => 'https://open.spotify.com/search/Sial%20Mahalini',
                'url_youtube' => 'https://music.youtube.com/search?q=Sial+Mahalini',
                'is_community_playlist' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Birds of a Feather',
                'artist' => 'Billie Eilish',
                'genre' => 'Soft Chill',
                'mood' => 'Calm, Happy',
                'url_spotify' => 'https://open.spotify.com/search/Birds%20of%20a%20Feather%20Billie%20Eilish',
                'url_youtube' => 'https://music.youtube.com/search?q=Birds+of+a+Feather+Billie+Eilish',
                'is_community_playlist' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Snooze',
                'artist' => 'SZA',
                'genre' => 'RnB',
                'mood' => 'Calm, Amazing',
                'url_spotify' => 'https://open.spotify.com/search/Snooze%20SZA',
                'url_youtube' => 'https://music.youtube.com/search?q=Snooze+SZA',
                'is_community_playlist' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Kisinan 2',
                'artist' => 'Masdddho',
                'genre' => 'Hipdut',
                'mood' => 'Sad, Happy',
                'url_spotify' => 'https://open.spotify.com/search/Kisinan%202%20Masdddho',
                'url_youtube' => 'https://music.youtube.com/search?q=Kisinan+2+Masdddho',
                'is_community_playlist' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Evaluasi',
                'artist' => 'Hindia',
                'genre' => 'Indie',
                'mood' => 'Anxious, Calm',
                'url_spotify' => 'https://open.spotify.com/search/Evaluasi%20Hindia',
                'url_youtube' => 'https://music.youtube.com/search?q=Evaluasi+Hindia',
                'is_community_playlist' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],

            // --- PLAYLIST KOMUNITAS ---
            [
                'title' => 'Self-Care & Warm Hugs 🌿',
                'artist' => 'Kurasi Komunitas Her Space',
                'genre' => 'Chill',
                'mood' => 'Anxious, Sad, Calm',
                'url_spotify' => 'https://open.spotify.com/genre/chill-page',
                'url_youtube' => 'https://music.youtube.com',
                'is_community_playlist' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Main Character Energy ✨',
                'artist' => 'Kurasi Komunitas Her Space',
                'genre' => 'Pop',
                'mood' => 'Amazing, Happy',
                'url_spotify' => 'https://open.spotify.com/genre/pop-page',
                'url_youtube' => 'https://music.youtube.com',
                'is_community_playlist' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}