<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use Carbon\Carbon;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    public function getPersonalityQuiz()
    {
        $quiz = Quiz::firstOrCreate(
            ['title' => 'Personality Type'],
            [
                'description' => 'Discover your personality traits and self-discovery type.',
                'is_active' => true,
            ]
        );

        $questions = [
            [
                'id' => 1,
                'question' => "When you're stressed, what usually helps?",
                'options' => [
                    ['id' => 'music', 'text' => 'Music', 'icon' => '🎵'],
                    ['id' => 'food', 'text' => 'Food', 'icon' => '🍲'],
                    ['id' => 'talk', 'text' => 'Talking to someone', 'icon' => '💬'],
                    ['id' => 'alone', 'text' => 'Being alone', 'icon' => '🌙'],
                ],
            ],
            [
                'id' => 2,
                'question' => 'How do you prefer to spend your ideal weekend?',
                'options' => [
                    ['id' => 'reading', 'text' => 'Reading with warm coffee', 'icon' => '☕'],
                    ['id' => 'adventure', 'text' => 'Exploring a new place', 'icon' => '🌿'],
                    ['id' => 'chill', 'text' => 'Cozy movie night at home', 'icon' => '🎬'],
                    ['id' => 'creative', 'text' => 'Working on creative projects', 'icon' => '🎨'],
                ],
            ],
            [
                'id' => 3,
                'question' => 'What brings you the most comfort during difficult days?',
                'options' => [
                    ['id' => 'routine', 'text' => 'Familiar routines & spaces', 'icon' => '🧸'],
                    ['id' => 'nature', 'text' => 'Nature and fresh air', 'icon' => '🌱'],
                    ['id' => 'journal', 'text' => 'Writing down my thoughts', 'icon' => '📖'],
                    ['id' => 'sleep', 'text' => 'A long undisturbed rest', 'icon' => '☁️'],
                ],
            ],
        ];

        return response()->json([
            'quiz' => [
                'id' => $quiz->id,
                'title' => $quiz->title,
                'description' => $quiz->description,
                'questions' => $questions,
            ],
        ]);
    }

    public function submitQuiz(Request $request)
    {
        $user = $request->user();
        $quiz = Quiz::where('title', 'Personality Type')->first() ?? Quiz::first();

        // Ambil hasil kalkulasi 32 soal dari Flutter
        $resultData = $request->input('result') ?? [
            'code' => $request->input('code', 'INFJ'),
            'type' => $request->input('code', 'INFJ'),
            'subtitle' => 'The Reflector',
            'scores' => $request->input('scores', [])
        ];

        $attempt = QuizAttempt::create([
            'user_id' => $user->id,
            'quiz_id' => $quiz ? $quiz->id : 1,
            'score' => 100,
            'result' => $resultData,
            'started_at' => Carbon::now()->subMinutes(5),
            'completed_at' => Carbon::now(),
        ]);

        ActivityLog::create([
            'user_id' => $user->id,
            'action' => 'completed personality quiz',
            'type' => 'Quiz',
            'subject_type' => QuizAttempt::class,
            'subject_id' => $attempt->id,
        ]);

        return response()->json([
            'message' => 'Quiz berhasil diselesaikan.',
            'result' => $resultData,
        ]);
    }

    public function getLatestResult(Request $request)
    {
        $attempt = $request->user()->quizAttempts()
            ->latest()
            ->first();

        if (! $attempt || ! $attempt->result) {
            // Default result matching mockup Panel 9
            return response()->json([
                'completed' => false,
                'result' => [
                    'type' => 'SOFT CHAOS',
                    'subtitle' => 'The Thoughtful Dreamer',
                    'description' => "You're thoughtful, curious, and sometimes overthink things more than you should. You enjoy small moments and tend to find comfort in familiar things.",
                    'traits' => [
                        ['name' => 'Overthinker', 'percent' => 42],
                        ['name' => 'Explorer', 'percent' => 28],
                        ['name' => 'Homebody', 'percent' => 20],
                        ['name' => 'Spontaneous', 'percent' => 10],
                    ],
                    'accuracy' => '82%',
                    'daily_tip' => 'You probably need a little break today. ♡',
                ],
            ]);
        }

        return response()->json([
            'completed' => true,
            'result' => $attempt->result,
        ]);
    }
}

