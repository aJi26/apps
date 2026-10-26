<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated =$request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token =$user->createToken('mobile')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
            'profile_setup_required' => true,
            'quiz_completed' => false,
        ], 201);
    }

    public function login(Request $request)
    {
        $validated =$request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email',$validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'],$user->password)) {
            return response()->json([
                'message' => 'Email atau password tidak valid.',
            ], 401);
        }

        $user->forceFill(['last_login_at' => now()])->save();
        $token =$user->createToken('mobile')->plainTextToken;
        $profile = Profile::where('user_id',$user->id)->first();

        $hasQuiz =$user->quizAttempts()->exists();

        return response()->json([
            'user' => $user,
            'token' => $token,
            'access_token' => $token,
            'token_type' => 'Bearer',
            'profile_setup_required' => ! $profile || ! $profile->birthday,
            'quiz_completed' => $hasQuiz,
        ]);
    }

    public function googleLogin(Request $request)
    {
        $validated =$request->validate([
            'email' => ['required', 'string', 'email'],
            'name' => ['required', 'string', 'max:255'],
            'is_register' => ['nullable', 'boolean'],
        ]);

        $isRegister =$request->boolean('is_register');
        $user = User::where('email',$validated['email'])->first();

        if ($isRegister) {
            if ($user) {
                return response()->json([
                    'message' => 'Akun sudah terdaftar. Silakan beralih ke halaman login.',
                ], 422);
            }

            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make(Str::random(16)),
            ]);
        } else {
            if (! $user) {
                return response()->json([
                    'message' => 'Akun belum terdaftar. Silakan buat akun terlebih dahulu.',
                ], 404);
            }
        }

        $user->forceFill(['last_login_at' => now()])->save();
        $token =$user->createToken('mobile')->plainTextToken;
        $profile = Profile::where('user_id',$user->id)->first();
        $hasQuiz =$user->quizAttempts()->exists();

        return response()->json([
            'user' => $user,
            'token' => $token,
            'access_token' => $token,
            'token_type' => 'Bearer',
            'profile_setup_required' => ! $profile || ! $profile->birthday,
            'quiz_completed' => $hasQuiz,
        ], 200);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $request->user()->update([
            'fcm_token' => $request->fcm_token,
        ]);

        return response()->json([
            'message' => 'Token FCM berhasil diperbarui!',
        ]);
    }

    public function logout(Request $request)
    {
        $token =$request->user()->currentAccessToken();

        if ($token instanceof \Laravel\Sanctum\PersonalAccessToken) {$token->delete();
        }

        return response()->json([
            'message' => 'Logout berhasil.',
        ]);
    }

    public function profileSetup(Request $request)
    {
        $validated =$request->validate([
            'name' => ['required', 'string', 'max:255'],
            'birthday' => ['sometimes', 'nullable', 'date', 'before_or_equal:today'],
            'avatar' => ['sometimes', 'string', 'max:20'],
        ]);

        $request->user()->update(['name' =>$validated['name']]);

        $profile = Profile::firstOrNew(['user_id' =>$request->user()->id]);

        if (array_key_exists('birthday', $validated)) {
            $profile->birthday =$validated['birthday'];
        }
        if (array_key_exists('avatar', $validated)) {
            $profile->avatar =$validated['avatar'];
        }

        $profile->save();

        return response()->json([
            'message' => 'Profil berhasil disimpan.',
            'profile' => $profile,
        ]);
    }
}