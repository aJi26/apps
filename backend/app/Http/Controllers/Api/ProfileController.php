<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Profile;
use App\Models\UserPreference;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();
        $user->load('profile', 'preferences');

        $preferences = $user->preferences->pluck('preference_value', 'preference_key');

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'birthday' => $user->profile?->birthday?->format('d M Y'),
                'birthday_raw' => $user->profile?->birthday?->toDateString(),
                'avatar' => $user->profile?->avatar,
                'avatar_url' => $user->profile?->avatar_path ? url('/api/profile/avatar') : null,
                'joined' => $user->created_at->format('d F Y'),
            ],
            'quiz_completed' => $user->quizAttempts()->exists(),
            'preferences' => [
                'music' => $preferences->get('music', 'Chill Lo-Fi'),
                'travel' => $preferences->get('travel', 'Japan & Nature'),
                'mood' => $preferences->get('mood', 'Calm'),
                'interests' => $preferences->get('interests', 'Photography & Art'),
            ],
            'privacy' => [
                'share_with_creator' => (bool) $preferences->get('share_with_creator', false),
                'share_mood' => (bool) $preferences->get('share_mood', false),
                'share_snapshots' => (bool) $preferences->get('share_snapshots', false),
                'share_goals' => (bool) $preferences->get('share_goals', false),
                'share_wishlist' => (bool) $preferences->get('share_wishlist', false),
                'share_quiz' => (bool) $preferences->get('share_quiz', false),
            ],
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'birthday' => ['sometimes', 'nullable', 'date'],
            'avatar' => ['sometimes', 'string', 'max:20'],
            'preferences' => ['sometimes', 'array'],
            'privacy' => ['sometimes', 'array:share_with_creator,share_mood,share_snapshots,share_goals,share_wishlist,share_quiz'],
            'privacy.share_with_creator' => ['sometimes', 'boolean'],
            'privacy.share_mood' => ['sometimes', 'boolean'],
            'privacy.share_snapshots' => ['sometimes', 'boolean'],
            'privacy.share_goals' => ['sometimes', 'boolean'],
            'privacy.share_wishlist' => ['sometimes', 'boolean'],
            'privacy.share_quiz' => ['sometimes', 'boolean'],
        ]);

        if (isset($validated['name'])) {
            $user->update(['name' => $validated['name']]);
        }

        if (array_key_exists('birthday', $validated)) {
            Profile::updateOrCreate(
                ['user_id' => $user->id],
                ['birthday' => $validated['birthday']]
            );
        }

        if (array_key_exists('avatar', $validated)) {
            Profile::updateOrCreate(['user_id' => $user->id], ['avatar' => $validated['avatar']]);
        }

        if (isset($validated['preferences'])) {
            foreach ($validated['preferences'] as $key => $val) {
                UserPreference::updateOrCreate(
                    ['user_id' => $user->id, 'preference_key' => $key],
                    ['preference_value' => $val]
                );
            }
        }

        if (isset($validated['privacy'])) {
            foreach ($validated['privacy'] as $key => $val) {
                UserPreference::updateOrCreate(
                    ['user_id' => $user->id, 'preference_key' => $key],
                    ['preference_value' => (bool) $val]
                );
            }
        }

        ActivityLog::create([
            'user_id' => $user->id,
            'action' => 'updated profile settings',
            'type' => 'Other',
        ]);

        return response()->json([
            'message' => 'Profile berhasil diperbarui.',
        ]);
    }

    public function uploadAvatar(Request $request)
    {
        $validated = $request->validate(['avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120']]);
        $profile = $request->user()->profile()->firstOrCreate([]);
        $oldPath = $profile->avatar_path;
        
        // UBAH: Upload ke Cloudinary
        $profile->avatar_path = $validated['avatar']->storeOnCloudinary('herspace/avatars')->getSecurePath();
        $profile->save();
        
        // Bersihkan foto profil lama
        if ($oldPath) {
            if (str_starts_with($oldPath, 'http')) {
                $this->deleteFromCloudinary($oldPath);
            } elseif (Storage::disk('local')->exists($oldPath)) {
                Storage::disk('local')->delete($oldPath);
            }
        }

        return response()->json([
            'message' => 'Avatar berhasil diperbarui.', 
            'avatar_url' => $profile->avatar_path // Kembalikan URL langsung
        ]);
    }

    public function avatar(Request $request)
    {
        $path = $request->user()->profile?->avatar_path;
        
        // UBAH: Jika path adalah URL Cloudinary, langsung redirect
        if ($path && str_starts_with($path, 'http')) {
            return redirect($path);
        }

        abort_unless($path && Storage::disk('local')->exists($path), 404);
        return Storage::disk('local')->response($path);
    }

    // TAMBAHKAN HELPER INI
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