<?php

use App\Http\Controllers\Admin\MonitorController;
use App\Models\User; // 1. Tambahkan import model User di sini
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('admin.login');
});

// 2. Rute Sementara untuk Setup Akun Admin
Route::get('/setup-admin-rahasia', function () {
    $user = User::updateOrCreate(
        ['email' => 'admin@herspace.com'],
        [
            'name' => 'Admin HerSpace',
            'password' => Hash::make('admin123'),
            // Hapus tanda komentar (//) di bawah jika tabel user kamu punya kolom role/is_admin:
            // 'role' => 'admin',
            // 'is_admin' => true,
        ]
    );

    return "Akun admin ({$user->email}) berhasil dibuat! Silakan login di /admin/login.";
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [MonitorController::class, 'loginPage'])->name('login');
    Route::post('/login', [MonitorController::class, 'login'])->middleware('throttle:5,1')->name('login.submit');

    Route::middleware(['auth', 'admin'])->group(function () {
        Route::post('/logout', [MonitorController::class, 'logout'])->name('logout');
        Route::get('/dashboard', [MonitorController::class, 'dashboard'])->name('dashboard');
        
        // CRUD Users / Account Management
        Route::get('/users', [MonitorController::class, 'users'])->name('users.index');
        Route::post('/users', [MonitorController::class, 'storeUser'])->name('users.store');
        Route::get('/users/{user}', [MonitorController::class, 'user'])->name('users.show');
        Route::post('/users/{user}/update', [MonitorController::class, 'updateUser'])->name('users.update');
        Route::post('/users/{user}/delete', [MonitorController::class, 'destroyUser'])->name('users.destroy');
        Route::get('/users/{user}/avatar', [MonitorController::class, 'userAvatar'])->name('user.avatar');
        
        // Profile Admin
        Route::post('/profile', [MonitorController::class, 'updateProfile'])->name('profile.update');
        
        // Features
        Route::get('/daily-potret', [MonitorController::class, 'dailyPotret'])->name('daily-potret.index');
        Route::get('/daily-potret/{user}', [MonitorController::class, 'userPotret'])->name('daily-potret.show');
        Route::get('/portraits/{portrait}/image', [MonitorController::class, 'portraitImage'])->name('portraits.image');
        Route::delete('/portraits/{portrait}', [MonitorController::class, 'destroyPortrait'])->name('portraits.destroy');
        Route::get('/activity', [MonitorController::class, 'activity'])->name('activity');
        Route::get('/settings', [MonitorController::class, 'settings'])->name('settings');
        Route::get('/analytics', [MonitorController::class, 'analytics'])->name('analytics');
    });
});