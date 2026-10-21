<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\DailyCheckin;
use App\Models\Goal;
use App\Models\Portrait;
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
                    'avatar' => $this->avatar($profile->user->name),
                ];
            })
            ->sortBy('daysUntil')
            ->take(5)
            ->values();

        $activities = ActivityLog::with('user')
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
                'avatar' => $this->avatar($user->name),
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
            'quizAttempts' => fn ($query) => $query->with('quiz')->latest(),
            'activityLogs' => fn ($query) => $query->latest()->take(15),
        ]);

        $todayCheckin = $user->dailyCheckins()
            ->whereDate('checkin_date', now()->toDateString())
            ->whereHas('portrait')
            ->exists();

        $portraits = $user->portraits
            ->sortByDesc(fn (Portrait $portrait) => $portrait->created_at)
            ->take(12)
            ->values()
            ->map(fn (Portrait $portrait) => [
                'id' => $portrait->id,
                'date' => $portrait->created_at->format('d M Y'),
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
                'avatar' => $this->avatar($user->name),
                'birthday' => $birthdayFormatted,
                'joined' => $user->created_at->format('d F Y'),
                'lastLogin' => $user->last_login_at?->format('d F Y • H:i') ?? 'Belum pernah login',
                'todayPotret' => $todayCheckin ? 'Completed ('.now()->format('d M Y').')' : 'Not Uploaded Yet',
                'stats' => [
                    'checkIns' => $user->dailyCheckins()->count(),
                    'goals' => $user->goals()->where('status', 'active')->count(),
                ],
            ],
            'userPotrets' => $portraits,
            'goals' => $user->goals->map(fn (Goal $goal) => [
                'id' => $goal->id,
                'title' => $goal->title,
                'category' => 'Goal',
                'target_date' => $goal->target_date ? 'Target: '.$goal->target_date->format('d M Y') : 'Target: 31 Dec 2025',
                'status' => ucfirst($goal->status),
                'progress' => $goal->description ? (str_contains($goal->description, '%') ? $goal->description : $goal->description.'%') : ($goal->status === 'completed' ? '100%' : '50%'),
            ])->values(),
            'quizzes' => $user->quizAttempts
                ->filter(fn ($attempt) => $attempt->quiz !== null)
                ->map(fn ($attempt) => [
                    'id' => $attempt->id,
                    'title' => $attempt->quiz->title,
                    'date' => ($attempt->completed_at ?? $attempt->started_at)->format('d M Y'),
                    'score' => $attempt->score === null ? 'Not scored' : $attempt->score.'%',
                    'status' => $attempt->completed_at ? 'Completed' : 'In Progress',
                ])->values(),
            'activityHistory' => $user->activityLogs->map(fn ($act) => [
                'id' => $act->id,
                'action' => $act->action,
                'type' => $act->type ?? 'Check-in',
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
            ->withCount('portraits')
            ->when($search !== '', fn ($query) => $query->whereRaw('LOWER(name) LIKE ?', ['%'.$search.'%']))
            ->latest()
            ->paginate(20)
            ->withQueryString()
            ->through(fn (User $user) => [
                'id' => $user->id,
                'name' => $user->name,
                'photosCount' => $user->portraits_count,
                'avatar' => $this->avatar($user->name),
                'initials' => strtoupper(substr($user->name, 0, 2)),
                'avatarBg' => 'E8ECE9',
                'avatarColor' => '2C3E35',
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
                'avatar' => $this->avatar($user->name),
            ]);

        return Inertia::render('Admin/DailyPotretShow', [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'avatar' => $this->avatar($user->name),
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

        $activities = ActivityLog::with('user')
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
        $role = $user->adminRoles()
            ->whereIn('role', ['admin', 'super_admin'])
            ->value('role');

        return Inertia::render('Admin/Settings', [
            'adminProfile' => [
                'name' => $user->name,
                'email' => $user->email,
                'role' => ucwords(str_replace('_', ' ', $role ?? 'Super Admin')),
                'phone' => '+62 812 3456 7890',
                'birthday' => '14 February 1998',
                'joined' => $user->created_at ? $user->created_at->format('d F Y') : '12 October 2025',
                'avatar' => $this->avatar($user->name, '#2C3E35', '#FFFFFF'),
            ],
        ]);
    }

    public function portraitImage(Portrait $portrait)
    {
        if (str_starts_with($portrait->path, 'http://') || str_starts_with($portrait->path, 'https://')) {
            return redirect($portrait->path);
        }

        abort_unless(Storage::disk('local')->exists($portrait->path), 404);

        return Storage::disk('local')->response($portrait->path);
    }

    private function formatActivity(ActivityLog $activity): array
    {
        $name = $activity->user?->name ?? 'Sarah Wijaya';

        return [
            'id' => $activity->id,
            'name' => $name,
            'action' => $activity->action,
            'type' => $activity->type ?? 'Other',
            'time' => $activity->created_at->diffForHumans(),
            'avatar' => $this->avatar($name),
        ];
    }

    private function avatar(string $name, string $background = '#E8ECE9', string $color = '#2C3E35'): string
    {
        $initials = htmlspecialchars(strtoupper(substr($name, 0, 2)), ENT_QUOTES, 'UTF-8');
        $svg = '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><rect width="96" height="96" rx="48" fill="'.$background.'"/><text x="48" y="55" text-anchor="middle" font-family="Plus Jakarta Sans,sans-serif" font-size="28" font-weight="700" fill="'.$color.'">'.$initials.'</text></svg>';

        return 'data:image/svg+xml,'.rawurlencode($svg);
    }
}
