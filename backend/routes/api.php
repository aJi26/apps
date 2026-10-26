<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DailyPotretController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\GoalController;
use App\Http\Controllers\Api\MusicController;
use App\Http\Controllers\Api\MusicRandomizerController;
use App\Http\Controllers\Api\NoteController;
use App\Http\Controllers\Api\FinanceController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\QuizController;
use App\Http\Controllers\Api\WishlistController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public Auth Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('auth/google-login', [AuthController::class, 'googleLogin']);

// Protected User Routes (Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    // Auth & Profile
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/profile-setup', [AuthController::class, 'profileSetup']);
    Route::get('/user', function (Request $request) {
        return $request->user()->load('profile');
    });
    Route::post('/user/fcm-token', [UserController::class, 'updateFcmToken']);
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::post('/profile/avatar', [ProfileController::class, 'uploadAvatar']);
    Route::get('/profile/avatar', [ProfileController::class, 'avatar']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::post('/dashboard/mood', [DashboardController::class, 'setMood']);

    // Daily Potret (Snapshot)
    Route::get('/potret/status', [DailyPotretController::class, 'checkTodayStatus']);
    Route::post('/potret/upload', [DailyPotretController::class, 'uploadPotret']);
    Route::get('/potret/gallery', [DailyPotretController::class, 'gallery']);
    Route::get('/portraits/{portrait}/image', [DailyPotretController::class, 'getImage']);

    // Goals CRUD
    Route::get('/goals', [GoalController::class, 'index']);
    Route::post('/goals', [GoalController::class, 'store']);
    Route::put('/goals/{goal}', [GoalController::class, 'update']);
    Route::delete('/goals/{goal}', [GoalController::class, 'destroy']);

    // Quiz & Personality
    Route::get('/quiz/personality', [QuizController::class, 'getPersonalityQuiz']);
    Route::post('/quiz/submit', [QuizController::class, 'submitQuiz']);
    Route::get('/quiz/result', [QuizController::class, 'getLatestResult']);

    // Notes CRUD
    Route::get('/notes', [NoteController::class, 'index']);
    Route::post('/notes', [NoteController::class, 'store']);
    Route::put('/notes/{note}', [NoteController::class, 'update']);
    Route::delete('/notes/{note}', [NoteController::class, 'destroy']);

    // Wishlist CRUD
    Route::get('/wishlist', [WishlistController::class, 'index']);
    Route::post('/wishlist', [WishlistController::class, 'store']);
    Route::put('/wishlist/{wishlist}', [WishlistController::class, 'update']);
    Route::delete('/wishlist/{wishlist}', [WishlistController::class, 'destroy']);

    // Finance & Budgeting
    Route::get('/finance/summary', [FinanceController::class, 'getSummary']);
    Route::post('/finance/transaction', [FinanceController::class, 'storeTransaction']);
    Route::put('/finance/transaction/{finance}', [FinanceController::class, 'updateTransaction']);
    Route::delete('/finance/transaction/{finance}', [FinanceController::class, 'destroyTransaction']);
    Route::post('/finance/target', [FinanceController::class, 'setTarget']);
    Route::post('/finance/sync-from-sheets', [FinanceController::class, 'syncFromSheets']);
    Route::post('/finance/spreadsheet-id', [FinanceController::class, 'storeSpreadsheetId']);

    // Music & Randomizer
    Route::get('/music/playlists', [MusicRandomizerController::class, 'playlists']);
    Route::get('/randomizer', [MusicRandomizerController::class, 'randomize']);

    // Fitur Music
    Route::prefix('music')->group(function () {
        Route::get('/daily', [MusicController::class, 'dailyRecommendation']);
        Route::get('/categories', [MusicController::class, 'categories']);
        Route::get('/community-playlists', [MusicController::class, 'communityPlaylists']);
        
        // Playlist Saya (Bookmark & Link Saver)
        Route::get('/my-playlists', [MusicController::class, 'myPlaylists']);
        Route::post('/my-playlists', [MusicController::class, 'storePlaylist']);
        Route::delete('/my-playlists/{id}', [MusicController::class, 'deletePlaylist']);
        Route::post('/my-playlists/{id}/tracks', [MusicController::class, 'addTrack']);
        Route::delete('/my-playlists/tracks/{trackId}', [MusicController::class, 'deleteTrack']);
    });
});
