<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
            'profile_setup_required' => true,
        ], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Email atau password tidak valid.',
            ], 401);
        }

        $user->forceFill(['last_login_at' => now()])->save();
        $token = $user->createToken('mobile')->plainTextToken;
        $profile = Profile::where('user_id', $user->id)->first();

        return response()->json([
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
            'profile_setup_required' => ! $profile || ! $profile->birthday,
        ]);
    }

    public function logout(Request $request)
    {
        $token = $request->user()->currentAccessToken();

        if ($token instanceof \Laravel\Sanctum\PersonalAccessToken) {
            $token->delete();
        }

        return response()->json([
            'message' => 'Logout berhasil.',
        ]);
    }

    public function profileSetup(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'birthday' => ['sometimes', 'nullable', 'date', 'before_or_equal:today'],
            'avatar' => ['sometimes', 'string', 'max:20'],
        ]);

        $request->user()->update(['name' => $validated['name']]);

        $profile = Profile::firstOrNew(['user_id' => $request->user()->id]);

        if (array_key_exists('birthday', $validated)) {
            $profile->birthday = $validated['birthday'];
        }
        if (array_key_exists('avatar', $validated)) {
            $profile->avatar = $validated['avatar'];
        }

        $profile->save();

        return response()->json([
            'message' => 'Profil berhasil disimpan.',
            'profile' => $profile,
        ]);
    }
}
