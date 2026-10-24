<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Note;
use Illuminate\Http\Request;

class NoteController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->query('search');
        $category = $request->query('category');

        $notes = $request->user()->notes()
            ->when($search, function ($query, $search) {
                $query->where(function ($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                        ->orWhere('content', 'like', "%{$search}%");
                });
            })
            ->when($category && $category !== 'All' && $category !== 'all', function ($query) use ($category) {
                $query->where('title', 'like', "%[{$category}]%")
                    ->orWhere('content', 'like', "%#{$category}%");
            })
            ->latest()
            ->get()
            ->map(function ($note) {
                // Extract category tag if present, default to Personal
                $category = 'Personal';
                if (preg_match('/\[(.*?)\]/', $note->title ?? '', $m)) {
                    $category = $m[1];
                }

                $cleanTitle = preg_replace('/\[(.*?)\]\s*/', '', $note->title ?? 'Untitled Note');

                return [
                    'id' => $note->id,
                    'title' => $cleanTitle,
                    'content' => $note->content,
                    'category' => $category,
                    'date' => $note->created_at->format('d M Y'),
                    'time' => $note->created_at->diffForHumans(),
                ];
            });

        return response()->json([
            'notes' => $notes,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'content' => ['required', 'string'],
            'category' => ['nullable', 'string', 'max:50'],
        ]);

        $category = $validated['category'] ?? 'Personal';
        $fullTitle = "[{$category}] " . $validated['title'];

        $note = $request->user()->notes()->create([
            'title' => $fullTitle,
            'content' => $validated['content'],
        ]);

        ActivityLog::create([
            'user_id' => $request->user()->id,
            'action' => 'wrote a note: ' . $validated['title'],
            'type' => 'Other',
            'subject_type' => Note::class,
            'subject_id' => $note->id,
        ]);

        return response()->json([
            'message' => 'Catatan berhasil disimpan.',
            'note' => $note,
        ], 201);
    }

    public function update(Request $request, Note $note)
    {
        abort_unless($note->user_id === $request->user()->id, 403);

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'content' => ['sometimes', 'string'],
            'category' => ['nullable', 'string', 'max:50'],
        ]);

        if (isset($validated['category']) || isset($validated['title'])) {
            $category = $validated['category'] ?? 'Personal';
            $title = $validated['title'] ?? $note->title;
            $cleanTitle = preg_replace('/\[(.*?)\]\s*/', '', $title);
            $validated['title'] = "[{$category}] " . $cleanTitle;
            unset($validated['category']);
        }

        $note->update($validated);

        return response()->json([
            'message' => 'Catatan berhasil diperbarui.',
            'note' => $note,
        ]);
    }

    public function destroy(Request $request, Note $note)
    {
        abort_unless($note->user_id === $request->user()->id, 403);

        $note->delete();

        return response()->json([
            'message' => 'Catatan berhasil dihapus.',
        ]);
    }
}

