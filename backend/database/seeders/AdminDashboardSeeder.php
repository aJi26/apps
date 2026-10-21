<?php

namespace Database\Seeders;

use App\Models\ActivityLog;
use App\Models\DailyCheckin;
use App\Models\Goal;
use App\Models\Portrait;
use App\Models\Profile;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminDashboardSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Quizzes
        $quizzes = [
            'Personality Type' => Quiz::firstOrCreate(['title' => 'Personality Type'], ['description' => 'Discover your personality traits', 'is_active' => true]),
            'Love Language' => Quiz::firstOrCreate(['title' => 'Love Language'], ['description' => 'Understand how you give and receive love', 'is_active' => true]),
            'Focus Mode' => Quiz::firstOrCreate(['title' => 'Focus Mode'], ['description' => 'Identify your optimal focus style', 'is_active' => true]),
            'Dream & Motivation' => Quiz::firstOrCreate(['title' => 'Dream & Motivation'], ['description' => 'Explore your inner drives', 'is_active' => true]),
        ];

        // 2. Sample Users matching the mockup design
        $sampleUsers = [
            [
                'name' => 'Sarah Wijaya',
                'email' => 'sarah@email.com',
                'birthday' => '2004-02-14',
                'is_active' => true,
                'created_at' => Carbon::now()->subDays(14),
                'last_login_at' => Carbon::now()->subHours(2),
                'photo_count' => 20,
            ],
            [
                'name' => 'Dinda Fitri',
                'email' => 'dinda@email.com',
                'birthday' => '2002-02-22',
                'is_active' => true,
                'created_at' => Carbon::now()->subDays(12),
                'last_login_at' => Carbon::now()->subHours(4),
                'photo_count' => 18,
            ],
            [
                'name' => 'Rara Septiani',
                'email' => 'rara@email.com',
                'birthday' => '2000-02-28',
                'is_active' => true,
                'created_at' => Carbon::now()->subDays(10),
                'last_login_at' => Carbon::now()->subHours(6),
                'photo_count' => 15,
            ],
            [
                'name' => 'Mayang Sari',
                'email' => 'mayang@email.com',
                'birthday' => '2001-05-18',
                'is_active' => false,
                'created_at' => Carbon::now()->subDays(16),
                'last_login_at' => Carbon::now()->subDays(3),
                'photo_count' => 12,
            ],
            [
                'name' => 'Nabila Azzahra',
                'email' => 'nabila@email.com',
                'birthday' => '2003-08-25',
                'is_active' => true,
                'created_at' => Carbon::now()->subDays(20),
                'last_login_at' => Carbon::now()->subDays(5),
                'photo_count' => 10,
            ],
        ];

        $aestheticPhotos = [
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=800&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&auto=format&fit=crop&q=80',
        ];

        foreach ($sampleUsers as $idx => $userData) {
            $user = User::updateOrCreate(
                ['email' => $userData['email']],
                [
                    'name' => $userData['name'],
                    'password' => Hash::make('password123'),
                    'is_active' => $userData['is_active'],
                    'created_at' => $userData['created_at'],
                    'last_login_at' => $userData['last_login_at'],
                ]
            );

            Profile::updateOrCreate(
                ['user_id' => $user->id],
                ['birthday' => $userData['birthday']]
            );

            // Daily check-ins & portraits
            for ($d = 0; $d < $userData['photo_count']; $d++) {
                $checkinDate = Carbon::now()->subDays($d)->toDateString();
                $checkin = DailyCheckin::firstOrCreate(
                    ['user_id' => $user->id, 'checkin_date' => $checkinDate]
                );

                $photoIndex = ($idx * 3 + $d) % count($aestheticPhotos);
                Portrait::firstOrCreate(
                    ['checkin_id' => $checkin->id],
                    [
                        'path' => $aestheticPhotos[$photoIndex],
                        'original_name' => "potret-{$checkinDate}.jpg",
                        'created_at' => Carbon::now()->subDays($d)->setHour(8)->setMinute(24),
                    ]
                );
            }
        }

        // Sarah Wijaya specific goals matching the mockup Panel 7
        $sarah = User::where('email', 'sarah@email.com')->first();
        if ($sarah) {
            $sarahGoals = [
                ['title' => 'Travel to Japan', 'description' => '60%', 'target_date' => '2026-06-30', 'status' => 'active'],
                ['title' => 'Build a personal brand', 'description' => '40%', 'target_date' => '2026-12-31', 'status' => 'active'],
                ['title' => 'Learn Japanese', 'description' => '70%', 'target_date' => '2025-12-31', 'status' => 'active'],
                ['title' => 'Save for a new laptop', 'description' => '20%', 'target_date' => '2025-12-31', 'status' => 'active'],
                ['title' => 'Drink 2L Water Daily', 'description' => '100%', 'target_date' => '2025-10-20', 'status' => 'completed'],
            ];

            foreach ($sarahGoals as $g) {
                Goal::firstOrCreate(
                    ['user_id' => $sarah->id, 'title' => $g['title']],
                    [
                        'description' => $g['description'],
                        'target_date' => $g['target_date'],
                        'status' => $g['status'],
                        'completed_at' => $g['status'] === 'completed' ? Carbon::now()->subDays(2) : null,
                    ]
                );
            }

            // Sarah Wijaya quiz attempts matching Panel 8
            $sarahQuizzes = [
                ['title' => 'Personality Type', 'score' => 85, 'date' => Carbon::now()->subDays(1)],
                ['title' => 'Love Language', 'score' => 78, 'date' => Carbon::now()->subDays(5)],
                ['title' => 'Focus Mode', 'score' => 90, 'date' => Carbon::now()->subDays(10)],
                ['title' => 'Dream & Motivation', 'score' => 80, 'date' => Carbon::now()->subDays(15)],
            ];

            foreach ($sarahQuizzes as $sq) {
                if (isset($quizzes[$sq['title']])) {
                    QuizAttempt::firstOrCreate(
                        ['user_id' => $sarah->id, 'quiz_id' => $quizzes[$sq['title']]->id],
                        [
                            'score' => $sq['score'],
                            'started_at' => $sq['date'],
                            'completed_at' => $sq['date'],
                        ]
                    );
                }
            }
        }

        // Dinda Fitri goals & quiz
        $dinda = User::where('email', 'dinda@email.com')->first();
        if ($dinda) {
            Goal::firstOrCreate(
                ['user_id' => $dinda->id, 'title' => 'Morning Meditation'],
                ['description' => '50%', 'target_date' => '2026-03-31', 'status' => 'active']
            );
            if (isset($quizzes['Personality Type'])) {
                QuizAttempt::firstOrCreate(
                    ['user_id' => $dinda->id, 'quiz_id' => $quizzes['Personality Type']->id],
                    ['score' => 92, 'started_at' => Carbon::now()->subDays(2), 'completed_at' => Carbon::now()->subDays(2)]
                );
            }
        }

        // Activity logs matching Panel 3 & 12
        $rara = User::where('email', 'rara@email.com')->first();
        $mayang = User::where('email', 'mayang@email.com')->first();
        $nabila = User::where('email', 'nabila@email.com')->first();

        if ($sarah) {
            ActivityLog::create([
                'user_id' => $sarah->id,
                'action' => 'completed daily check-in',
                'type' => 'Check-in',
                'created_at' => Carbon::now()->subHours(2),
            ]);
        }
        if ($dinda) {
            ActivityLog::create([
                'user_id' => $dinda->id,
                'action' => 'updated a goal',
                'type' => 'Goals',
                'created_at' => Carbon::now()->subHours(4),
            ]);
        }
        if ($rara) {
            ActivityLog::create([
                'user_id' => $rara->id,
                'action' => 'completed a quiz',
                'type' => 'Quiz',
                'created_at' => Carbon::now()->subHours(6),
            ]);
        }
        if ($mayang) {
            ActivityLog::create([
                'user_id' => $mayang->id,
                'action' => 'profile updated',
                'type' => 'Other',
                'created_at' => Carbon::now()->subDays(3)->setHour(9)->setMinute(40),
            ]);
        }
        if ($nabila) {
            ActivityLog::create([
                'user_id' => $nabila->id,
                'action' => 'login',
                'type' => 'Other',
                'created_at' => Carbon::now()->subDays(5)->setHour(9)->setMinute(20),
            ]);
        }
    }
}
