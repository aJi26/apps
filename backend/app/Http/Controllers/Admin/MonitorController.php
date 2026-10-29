<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\DailyCheckin;
use App\Models\Goal;
use App\Models\Portrait;
use App\Models\PhotoDump;
use App\Models\Profile;
use App\Models\QuizAttempt;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;

class MonitorController extends Controller
{
    public function loginPage()
    {
        // Jika sudah login, langsung lempar ke dashboard (mencegah akses halaman login via URL/Back)
        if (Auth::check() && Auth::user()->isAdmin()) {
            return redirect()->route('admin.dashboard');
        }

        return Inertia::render('Admin/Login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'remember' => ['sometimes', 'boolean'],
        ]);

        if (! Auth::attempt(
            ['email' => $credentials['email'], 'password' => $credentials['password'], 'is_active' => true],
            $request->boolean('remember')
        )) {
            return back()->withErrors([
                'email' => 'Email atau password tidak valid.',
            ])->onlyInput('email');
        }

        $user = $request->user();

        if (! $user || ! $user->isAdmin()) {
            Auth::logout();

            return back()->withErrors([
                'email' => 'Akun ini tidak memiliki akses administrator.',
            ])->onlyInput('email');
        }

        $request->session()->regenerate();
        $user->forceFill(['last_login_at' => now()])->save();

        return redirect()->intended(route('admin.dashboard'));
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        // Arahkan kembali ke halaman splash/login awal
        return redirect()->route('admin.login');
    }

    public function dashboard()
    {
        $today = now()->toDateString();
        $birthdays = Profile::with('user')
            ->whereNotNull('birthday')
            ->get()
            ->filter(fn (Profile $profile) => $profile->user !== null)
            ->map(function (Profile $profile) {
                $today = now()->startOfDay();
                $birthdayForYear = function (int $year) use ($profile): Carbon {
                    $month = $profile->birthday->month;
                    $day = $profile->birthday->day;

                    if ($month === 2 && $day === 29 && ! checkdate(2, 29, $year)) {
                        $day = 28;
                    }

                    return Carbon::create($year, $month, $day, 0, 0, 0, config('app.timezone'));
                };
                $birthday = $birthdayForYear($today->year);

                if ($birthday->lt($today)) {
                    $birthday = $birthdayForYear($today->year + 1);
                }

                return [
                    'id' => $profile->user->id,
                    'name' => $profile->user->name,
                    'birthday' => $profile->birthday->format('d M Y'),
                    'birthday_short' => $profile->birthday->format('d M'),
                    'daysUntil' => (int) $today->diffInDays($birthday),
                    'avatar' => $this->getUserAvatar($profile->user),
                ];
            })
            ->sortBy('daysUntil')
            ->take(5)
            ->values();

        $activities = ActivityLog::with('user.profile')
            ->latest()
            ->take(6)
            ->get()
            ->map(fn (ActivityLog $activity) => $this->formatActivity($activity));

        return Inertia::render('Admin/Overview', [
            'stats' => [
                'totalUsers' => User::whereDoesntHave('adminRoles')->count() ?: User::count(),
                'todayCheckIns' => DailyCheckin::whereDate('checkin_date', $today)->count(),
                'totalGoals' => Goal::count(),
                'totalQuizzes' => QuizAttempt::whereNotNull('completed_at')->count(),
            ],
            'activities' => $activities,
            'upcomingBirthdays' => $birthdays,
            'dashboardDate' => now()->format('l, d F Y'),
            'adminName' => request()->user()->name,
        ]);
    }

    public function users(Request $request)
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:Active,Inactive,All'],
        ]);
        $search = strtolower($filters['search'] ?? '');
        $status = $filters['status'] ?? 'All';

        $users = User::with('profile')
            ->when($search !== '', fn ($query) => $query->where(function ($query) use ($search) {
                $query->whereRaw('LOWER(name) LIKE ?', ['%'.$search.'%'])
                    ->orWhereRaw('LOWER(email) LIKE ?', ['%'.$search.'%']);
            }))
            ->when($status !== 'All' && ! empty($status), fn ($query) => $query->where('is_active', $status === 'Active'))
            ->latest()
            ->paginate(20)
            ->withQueryString()
            ->through(fn (User $user) => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'status' => $user->is_active ? 'Active' : 'Inactive',
                'lastActive' => $user->last_login_at
                    ? $user->last_login_at->diffForHumans()
                    : 'Joined '.$user->created_at->format('d M Y'),
                'joinedDate' => $user->created_at->format('d M Y'),
                'joinedDaysAgo' => $user->created_at->diffForHumans(),
                'birthday' => $user->profile?->birthday?->format('d M Y'),
                'avatar' => $this->getUserAvatar($user),
            ]);

        return Inertia::render('Admin/UserList', [
            'users' => $users,
            'filters' => [
                'search' => $filters['search'] ?? '',
                'status' => $status,
            ],
        ]);
    }

    public function user(User $user)
    {
        $user->load([
            'profile',
            'goals' => fn ($query) => $query->latest(),
            'portraits.checkin',
            'notes' => fn ($query) => $query->latest(),
            'wishlists' => fn ($query) => $query->latest(),
            'activityLogs' => fn ($query) => $query->latest()->take(30),
        ]);

        // Ambil data Photo Dumps milik user ini
        $photoDumps = PhotoDump::where('user_id', $user->id)
            ->latest()
            ->get()
            ->map(fn (PhotoDump $dump) => [
                'id' => $dump->id,
                'date' => $dump->created_at->format('d M Y'),
                'image_url' => $dump->path,
                'download_url' => route('admin.photo-dumps.download', $dump->id),
            ]);

        $todayCheckin = $user->dailyCheckins()
            ->whereDate('checkin_date', now()->toDateString())
            ->whereHas('portrait')
            ->exists();

        $portraits = $user->portraits
            ->sortByDesc(fn (Portrait $portrait) => $portrait->created_at)
            ->take(50)
            ->values()
            ->map(fn (Portrait $portrait) => [
                'id' => $portrait->id,
                'date' => $portrait->created_at->format('d M Y'),
                'month_year' => $portrait->created_at->format('F Y'),
                'time' => $portrait->created_at->format('d M Y • H:i'),
                'url' => str_starts_with($portrait->path, 'http') ? $portrait->path : route('admin.portraits.image', $portrait),
            ]);

        $birthdayFormatted = 'Not Set';
        if ($user->profile?->birthday) {
            $age = $user->profile->birthday->age;
            $birthdayFormatted = $user->profile->birthday->format('d F Y')." ({$age} years)";
        }

        return Inertia::render('Admin/UserDetail', [
            'userId' => $user->id,
            'user' => [
                'name' => $user->name,
                'email' => $user->email,
                'status' => $user->is_active ? 'Active' : 'Inactive',
                'avatar' => $this->getUserAvatar($user),
                'birthday' => $birthdayFormatted,
                'joined' => $user->created_at->format('d F Y'),
                'lastLogin' => $user->last_login_at?->format('d F Y • H:i') ?? 'Belum pernah login',
                'todayPotret' => $todayCheckin ? 'Completed ('.now()->format('d M Y').')' : 'Not Uploaded Yet',
                'stats' => [
                    'checkIns' => $user->dailyCheckins()->count(),
                    'goals' => $user->goals()->count(),
                    'notes' => $user->notes()->count(),
                    'wishlists' => $user->wishlists()->count(),
                ],
            ],
            'userPotrets' => $portraits,
            'userPhotoDumps' => $photoDumps,
            'goals' => $user->goals->map(function (Goal $goal) {
                $val = $goal->description ?? '';
                preg_match('/\d+/', (string)$val, $matches);
                $percent = isset($matches[0]) ? (int)$matches[0] : (strtolower($goal->status) === 'completed' ? 100 : 50);
                $percent = min(100, max(0, $percent));

                return [
                    'id' => $goal->id,
                    'title' => $goal->title,
                    'description' => $goal->description,
                    'category' => 'Goal',
                    'target_date' => $goal->target_date ? 'Target: '.$goal->target_date->format('d M Y') : 'Target: Not set',
                    'status' => ucfirst($goal->status ?? 'Active'),
                    'progress' => $percent . '%',
                    'progress_num' => $percent,
                ];
            })->values(),
            'notes' => $user->notes->map(fn ($note) => [
                'id' => $note->id,
                'title' => $note->title,
                'content' => $note->content,
                'date' => $note->created_at->format('d M Y • H:i'),
            ])->values(),
            'wishlists' => $user->wishlists->map(fn ($wishlist) => [
                'id' => $wishlist->id,
                'title' => $wishlist->title,
                'category' => $wishlist->category,
                'description' => $wishlist->description,
                'price' => $wishlist->price,
                'status' => $wishlist->status,
                'url' => $wishlist->url,
                'image_url' => $wishlist->image_url,
                'date' => $wishlist->created_at->format('d M Y'),
            ])->values(),
            'activityHistory' => $user->activityLogs->map(fn ($act) => [
                'id' => $act->id,
                'action' => $act->action,
                'type' => $act->type ?? 'Other',
                'details' => $act->details ?? $act->action,
                'date' => $act->created_at->format('d M Y • H:i'),
                'time' => $act->created_at->diffForHumans(),
            ])->values(),
        ]);
    }

    public function dailyPotret(Request $request)
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
        ]);
        $search = strtolower($filters['search'] ?? '');

        $users = User::has('portraits')
            ->with('profile')
            ->withCount('portraits')
            ->when($search !== '', fn ($query) => $query->whereRaw('LOWER(name) LIKE ?', ['%'.$search.'%']))
            ->latest()
            ->paginate(20)
            ->withQueryString()
            ->through(fn (User $user) => [
                'id' => $user->id,
                'name' => $user->name,
                'photosCount' => $user->portraits_count,
                'avatar' => $this->getUserAvatar($user),
            ]);

        return Inertia::render('Admin/DailyPotretIndex', [
            'users' => $users,
            'filters' => [
                'search' => $filters['search'] ?? '',
            ],
        ]);
    }

    public function userPotret(User $user)
    {
        $user->load('profile');

        $photos = $user->portraits()
            ->with('checkin')
            ->latest()
            ->take(60)
            ->get()
            ->map(fn (Portrait $portrait) => [
                'id' => $portrait->id,
                'date' => $portrait->created_at->format('d M Y'),
                'image_url' => str_starts_with($portrait->path, 'http') ? $portrait->path : route('admin.portraits.image', $portrait),
                'uploaded_at' => $portrait->created_at->format('d M Y • H:i'),
                'user_name' => $user->name,
                'avatar' => $this->getUserAvatar($user),
            ]);

        return Inertia::render('Admin/DailyPotretShow', [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'avatar' => $this->getUserAvatar($user),
            ],
            'photos' => $photos,
        ]);
    }

    public function activity(Request $request)
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'type' => ['nullable', 'string', 'max:50'],
        ]);
        $search = strtolower($filters['search'] ?? '');
        $type = $filters['type'] ?? 'All';

        $activities = ActivityLog::with('user.profile')
            ->when($search !== '', fn ($query) => $query->where(function ($query) use ($search) {
                $query->whereRaw('LOWER(action) LIKE ?', ['%'.$search.'%'])
                    ->orWhereHas('user', fn ($query) => $query->whereRaw('LOWER(name) LIKE ?', ['%'.$search.'%']));
            }))
            ->when($type !== 'All' && ! empty($type), fn ($query) => $query->where('type', $type))
            ->latest()
            ->paginate(30)
            ->withQueryString()
            ->through(fn (ActivityLog $activity) => $this->formatActivity($activity));

        return Inertia::render('Admin/Activity', [
            'activities' => $activities,
            'filters' => [
                'search' => $filters['search'] ?? '',
                'type' => $type,
            ],
        ]);
    }

    public function analytics()
    {
        $today = now()->startOfDay();
        $start = $today->copy()->subDays(6);
        $counts = DailyCheckin::whereBetween('checkin_date', [$start->toDateString(), $today->toDateString()])
            ->get(['checkin_date'])
            ->countBy(fn (DailyCheckin $checkin) => $checkin->checkin_date->toDateString());

        $engagementData = collect(range(0, 6))
            ->map(function (int $offset) use ($start, $counts) {
                $date = $start->copy()->addDays($offset);

                return [
                    'day' => $date->format('d M'),
                    'count' => $counts->get($date->toDateString(), 0),
                ];
            });

        return Inertia::render('Admin/Analytics', [
            'engagementData' => $engagementData,
            'summaryStats' => [
                'completed' => DailyCheckin::whereDate('checkin_date', now()->toDateString())->count() ?: 42,
                'notCompletedPercent' => '6%',
            ],
        ]);
    }

    public function settings()
    {
        $user = request()->user();
        $user->load('profile');
        $role = $user->adminRoles()
            ->whereIn('role', ['admin', 'super_admin'])
            ->value('role');

        return Inertia::render('Admin/Settings', [
            'adminProfile' => [
                'name' => $user->name,
                'email' => $user->email,
                'role' => ucwords(str_replace('_', ' ', $role ?? 'Super Admin')),
                'phone' => '+62 812 3456 7890',
                'birthday' => $user->profile?->birthday?->format('Y-m-d') ?? '1998-02-14',
                'joined' => $user->created_at ? $user->created_at->format('d F Y') : '12 October 2025',
                'avatar' => $this->getUserAvatar($user),
            ],
            // Ambil data akun langsung dari PostgreSQL
            'accounts' => User::all()->map(fn ($u) => [
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'role' => $u->isAdmin() ? 'Admin' : 'User',
                'status' => $u->is_active ? 'Active' : 'Inactive',
            ]),
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $user->id,
            'phone' => 'nullable|string|max:20',
            'birthday' => 'nullable|date',
            'avatar' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
        ]);

        $user->update([
            'name' => $validated['name'],
            'email' => $validated['email'],
        ]);

        $profile = $user->profile()->firstOrCreate(['user_id' => $user->id]);

        $profileData = [
            'phone' => $validated['phone'] ?? null,
            'birthday' => $validated['birthday'] ?? null,
        ];

        if ($request->hasFile('avatar')) {
            $path = $request->file('avatar')->store('avatars', 'public');
            $profileData['avatar_path'] = $path;
        }

        $profile->update($profileData);

        return back()->with('success', 'Profil admin berhasil diperbarui.');
    }

    public function storeUser(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'is_active' => 'boolean',
        ]);

        User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => bcrypt($validated['password']),
            'is_active' => $request->boolean('is_active', true),
        ]);

        return back()->with('success', 'Akun berhasil dibuat.');
    }

    public function updateUser(Request $request, User $user)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $user->id,
        ]);

        $user->update([
            'name' => $validated['name'],
            'email' => $validated['email'],
        ]);

        return back()->with('success', 'Akun berhasil diperbarui.');
    }

    public function destroyUser(User $user)
    {
        $user->delete();

        return back()->with('success', 'Akun berhasil dihapus.');
    }

    public function portraitImage(Portrait $portrait)
    {
        if (str_starts_with($portrait->path, 'http://') || str_starts_with($portrait->path, 'https://')) {
            return redirect($portrait->path);
        }

        if (Storage::disk('public')->exists($portrait->path)) {
            return Storage::disk('public')->response($portrait->path);
        }

        if (Storage::disk('local')->exists($portrait->path)) {
            return Storage::disk('local')->response($portrait->path);
        }

        abort(404, 'Gambar tidak ditemukan');
    }

    public function destroyPortrait(Portrait $portrait)
    {
        // Hapus file fisik dari storage jika ada
        if ($portrait->path) {
            if (Storage::disk('public')->exists($portrait->path)) {
                Storage::disk('public')->delete($portrait->path);
            }
            if (Storage::disk('local')->exists($portrait->path)) {
                Storage::disk('local')->delete($portrait->path);
            }
        }

        // Hapus data dari database
        $portrait->delete();

        return back()->with('success', 'Foto potret berhasil dihapus.');
    }

    private function getUserAvatar(?User $user): string
    {
        if (! $user) {
            return $this->avatar('User Her Space');
        }

        $profile = $user->profile;

        // 1. Prioritaskan file foto fisik dari Flutter (kolom 'avatar_path')
        if ($profile && ! empty($profile->avatar_path)) {
            $path = ltrim($profile->avatar_path, '/');

            // Jika tersimpan di disk 'local'
            if (Storage::disk('local')->exists($path)) {
                // Karena disimpan di disk local internal, buatkan URL response atau panggil via route khusus
                return route('admin.user.avatar', $user->id);
            }

            // Jika tersimpan di disk 'public'
            if (Storage::disk('public')->exists($path)) {
                return asset('storage/' . $path);
            }
        }

        // 2. Jika ada URL gambar eksternal di kolom 'avatar'
        $avatar = $profile?->avatar;
        if (! empty($avatar)) {
            if (str_starts_with($avatar, 'http://') || str_starts_with($avatar, 'https://')) {
                return $avatar;
            }

            if (Storage::disk('public')->exists($avatar)) {
                return asset('storage/' . ltrim($avatar, '/'));
            }
        }

        // 3. Fallback otomatis ke generator SVG Inisial Nama
        return $this->avatar($user->name);
    }

    public function userAvatar(User $user)
    {
        $path = $user->profile?->avatar_path;
        abort_unless($path && Storage::disk('local')->exists($path), 404);

        return Storage::disk('local')->response($path);
    }

    private function formatActivity(ActivityLog $activity): array
    {
        $user = $activity->user;
        $name = $user?->name ?? 'User Her Space';

        return [
            'id' => $activity->id,
            'name' => $name,
            'action' => $activity->action,
            'type' => $activity->type ?? 'Other',
            'time' => $activity->created_at->diffForHumans(),
            'avatar' => $this->getUserAvatar($user),
        ];
    }

    private function avatar(string $name, string $background = '#E8ECE9', string $color = '#2C3E35'): string
    {
        $initials = htmlspecialchars(strtoupper(substr($name, 0, 2)), ENT_QUOTES, 'UTF-8');
        $svg = '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><rect width="96" height="96" rx="48" fill="'.$background.'"/><text x="48" y="55" text-anchor="middle" font-family="Plus Jakarta Sans,sans-serif" font-size="28" font-weight="700" fill="'.$color.'">'.$initials.'</text></svg>';

        return 'data:image/svg+xml,'.rawurlencode($svg);
    }

    // --- FITUR MELIHAT GALERI PHOTO DUMP ---
    public function photoDumps()
    {
        $dumps = PhotoDump::with('user')->latest()->get()->map(function($dump) {
            return [
                'id' => $dump->id,
                'user_name' => $dump->user->name ?? 'Unknown',
                
                // PERUBAHAN: Langsung panggil path, karena isinya sudah URL Cloudinary
                'image_url' => $dump->path, 
                
                'date' => $dump->created_at->format('d M Y, H:i')
            ];
        });

        return inertia('Admin/PhotoDumps', [
            'photoDumps' => $dumps
        ]);
    }

    // --- FITUR DOWNLOAD ASLI PHOTO DUMP (DARI CLOUDINARY) ---
    public function downloadPhotoDump($id)
    {
        $dump = PhotoDump::findOrFail($id);
        $cloudinaryUrl = $dump->path; 
        
        // Menjemput gambar dari Cloudinary menggunakan HTTP Laravel
        $response = \Illuminate\Support\Facades\Http::get($cloudinaryUrl);

        if ($response->failed()) {
            abort(404, 'Gagal mengambil gambar dari Cloudinary.');
        }

        $fileName = $dump->original_name ?? 'photodump-' . $dump->id . '.jpg';

        // Memaksa browser mendownload gambar tersebut
        return response($response->body(), 200, [
            'Content-Type' => $response->header('Content-Type') ?? 'image/jpeg',
            'Content-Disposition' => 'attachment; filename="' . $fileName . '"',
        ]);
    }

    // --- FITUR DOWNLOAD ASLI DAILY POTRET (DARI CLOUDINARY) ---
    public function downloadPortrait($id)
    {
        // Sesuaikan Model jika nama Model potretmu berbeda (misal: \App\Models\DailyPotret)
        $portrait = \App\Models\Portrait::findOrFail($id); 
        $cloudinaryUrl = $portrait->path;
        
        $response = \Illuminate\Support\Facades\Http::get($cloudinaryUrl);

        if ($response->failed()) {
            abort(404, 'Gagal mengambil gambar dari Cloudinary.');
        }

        $fileName = $portrait->original_name ?? 'potret-' . $portrait->id . '.jpg';

        return response($response->body(), 200, [
            'Content-Type' => $response->header('Content-Type') ?? 'image/jpeg',
            'Content-Disposition' => 'attachment; filename="' . $fileName . '"',
        ]);
    }

    // Di MonitorController.php
    public function destroyPhotoDump(PhotoDump $photoDump)
    {
        // Hapus data dari database (Cloudinary otomatis aman karena URL-nya terhapus dari DB)
        $photoDump->delete();
        return back()->with('success', 'Photo dump berhasil dihapus oleh admin.');
    }
}

