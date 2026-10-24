<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Goal;
use Carbon\Carbon;
use Illuminate\Http\Request;

class GoalController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->query('status'); // 'active', 'completed', 'all'

        $goals = $request->user()->goals()
            ->when($status && $status !== 'all' && $status !== 'All', function ($query) use ($status) {
                $query->where('status', strtolower($status));
            })
            ->latest()
            ->get()
            ->map(function ($goal) {
                // Parse percentage from description or progress
                $progressInt = 30;
                if ($goal->description && preg_match('/(\d+)%?/', $goal->description, $matches)) {
                    $progressInt = (int) $matches[1];
                } elseif ($goal->status === 'completed') {
                    $progressInt = 100;
                }

                return [
                    'id' => $goal->id,
                    'title' => $goal->title,
                    'description' => $goal->description,
                    'status' => $goal->status,
                    'progress' => $progressInt,
                    'target_date' => $goal->target_date ? $goal->target_date->format('M Y') : 'Dec 2025',
                    'target_date_full' => $goal->target_date ? $goal->target_date->format('d M Y') : null,
                    'completed_at' => $goal->completed_at ? $goal->completed_at->format('d M Y') : null,
                ];
            });

        return response()->json([
            'goals' => $goals,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:255'],
            'target_date' => ['nullable', 'date'],
            'progress' => ['nullable', 'integer', 'min:0', 'max:100'],
        ]);

        $progress = $validated['progress'] ?? 20;
        $description = $validated['description'] ?? "{$progress}%";

        $goal = $request->user()->goals()->create([
            'title' => $validated['title'],
            'description' => $description,
            'target_date' => $validated['target_date'] ?? Carbon::now()->addMonths(6),
            'status' => 'active',
        ]);

        ActivityLog::create([
            'user_id' => $request->user()->id,
            'action' => 'created a new goal: ' . $goal->title,
            'type' => 'Goals',
            'subject_type' => Goal::class,
            'subject_id' => $goal->id,
        ]);

        return response()->json([
            'message' => 'Goal berhasil dibuat.',
            'goal' => $goal,
        ], 201);
    }

    public function update(Request $request, Goal $goal)
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:255'],
            'status' => ['sometimes', 'in:active,completed'],
            'target_date' => ['nullable', 'date'],
            'progress' => ['nullable', 'integer', 'min:0', 'max:100'],
        ]);

        if (isset($validated['progress'])) {
            $validated['description'] = "{$validated['progress']}%";
            if ($validated['progress'] >= 100) {
                $validated['status'] = 'completed';
                $validated['completed_at'] = now();
            }
        }

        if (isset($validated['status']) && $validated['status'] === 'completed' && ! $goal->completed_at) {
            $validated['completed_at'] = now();
        }

        $goal->update($validated);

        ActivityLog::create([
            'user_id' => $request->user()->id,
            'action' => 'updated goal: ' . $goal->title,
            'type' => 'Goals',
            'subject_type' => Goal::class,
            'subject_id' => $goal->id,
        ]);

        return response()->json([
            'message' => 'Goal berhasil diperbarui.',
            'goal' => $goal,
        ]);
    }

    public function destroy(Request $request, Goal $goal)
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $goal->delete();

        return response()->json([
            'message' => 'Goal berhasil dihapus.',
        ]);
    }
}

