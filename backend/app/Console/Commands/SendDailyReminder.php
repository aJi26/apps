<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SendDailyReminders extends Command
{
    protected $signature = 'reminders:send {type}';
    protected $description = 'Kirim notifikasi terjadwal (checkin, birthday, goals)';

    public function handle()
    {
        $type = $this->argument('type');
        $today = now();

        switch ($type) {
            case 'checkin':
                $this->sendCheckinReminders($today);
                break;
            case 'birthday':
                $this->sendBirthdayWishes($today);
                break;
            case 'goals':
                $this->sendGoalsReminders($today);
                break;
            case 'finance':
                $this->sendFinanceReminders($today);
                break;
            default:
                $this->sendCheckinReminders($today);
                $this->sendBirthdayWishes($today);
                $this->sendGoalsReminders($today);
                $this->sendFinanceReminders($today);
                break;
        }
    }
    
    private function sendCheckinReminders($today)
    {
        // Filter profile::notif_checkin dikomentari sementara agar memudahkan testing
        $users = User::whereNotNull('fcm_token')
            ->whereHas('profile', function ($q) {
                $q->where('notif_checkin', true);
            })
            ->whereDoesntHave('portraits', function ($q) use ($today) {
                $q->whereDate('portraits.created_at', $today);
            })->get();

        if ($users->isEmpty()) {
            $this->warn("Tidak ada pengguna yang memenuhi kriteria (FCM Token NULL, notif dimatikan, atau sudah check-in).");
            return;
        }

        $this->info("Ditemukan {$users->count()} pengguna. Mengirimkan notifikasi...");

        foreach ($users as $user) {
            $title = "Selamat Pagi, {$user->name}! ☀️";
            $body = "Gimana perasaanmu pagi ini? Yuk abadikan potret dan catat mood hari inimu di Her Space!";
            
            $this->sendFcmPush($user->fcm_token, $title, $body);
        }
    }

    private function sendBirthdayWishes($today)
    {
        $users = User::whereNotNull('fcm_token')
            ->whereHas('profile', function ($q) use ($today) {
                $q->where('notif_birthday', true)
                  ->whereNotNull('birth_date')
                  ->whereMonth('birth_date', $today->month)
                  ->whereDay('birth_date', $today->day);
            })->get();

        if ($users->isEmpty()) {
            $this->warn("Tidak ada pengguna yang ulang tahun hari ini atau pengaturan notifikasi dimatikan.");
            return;
        }

        $this->info("Ditemukan {$users->count()} pengguna berulang tahun. Mengirim ucapan...");

        foreach ($users as $user) {
            $title = "Selamat Ulang Tahun, {$user->name}! 🥳🎉";
            $body = "Semoga harimu jadi lebih baik dan penuh kebahagiaan. Ada ruang spesial menunggumu hari ini ✨";

            $this->sendFcmPush($user->fcm_token, $title, $body);
        }
    }

    private function sendGoalsReminders($today)
    {
        $users = User::whereNotNull('fcm_token')
            ->whereHas('profile', function ($q) {
                $q->where('notif_goals', true);
            })
            ->whereHas('goals', function ($q) {
                $q->whereNull('completed_at')
                  ->where('status', '!=', 'completed');
            })
            ->whereDoesntHave('goals', function ($q) use ($today) {
                $q->where(function ($sub) use ($today) {
                    $sub->whereDate('created_at', $today)
                        ->orWhereDate('updated_at', $today);
                });
            })
            ->get();

        if ($users->isEmpty()) {
            $this->warn("Tidak ada pengguna yang memenuhi kriteria (sudah buat/update goal hari ini atau tidak punya goal aktif).");
            return;
        }

        $this->info("Ditemukan {$users->count()} pengguna. Mengirimkan notifikasi goals...");

        foreach ($users as $user) {
            $title = "Progres Impianmu 📝";
            $body = "Langkah kecil tetaplah progres! Yuk buat atau perbarui targetmu hari ini.";

            $this->sendFcmPush($user->fcm_token, $title, $body);
        }
    }

    private function sendFinanceReminders($today)
    {
        $users = User::whereNotNull('fcm_token')
            ->whereDoesntHave('finances', function ($q) use ($today) {
                $q->where(function ($sub) use ($today) {
                    $sub->whereDate('created_at', $today)
                        ->orWhereDate('updated_at', $today);
                });
            })
            ->get();

        if ($users->isEmpty()) {
            $this->warn("Tidak ada pengguna yang memenuhi kriteria (semua user sudah catat keuangan hari ini).");
            return;
        }

        $this->info("Ditemukan {$users->count()} pengguna. Mengirimkan notifikasi keuangan...");

        foreach ($users as $user) {
            $title = "Catat Keuangan Hari Ini 💰";
            $body = "Sudah mencatat pengeluaran atau pemasukanmu hari ini? Yuk rapikan catatan keuanganmu!";

            $this->sendFcmPush($user->fcm_token, $title, $body);
        }
    }

    private function base64UrlEncode($data)
    {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
    }

    private function getCredentialsJson()
    {
        if (env('FIREBASE_CREDENTIALS_BASE64')) {
            return base64_decode(env('FIREBASE_CREDENTIALS_BASE64'));
        }

        $credentialsPath = storage_path('app/firebase/firebase-credentials.json');
        if (file_exists($credentialsPath)) {
            return file_get_contents($credentialsPath);
        }

        return null;
    }

    private function getGoogleAccessToken()
    {
        $jsonContent = $this->getCredentialsJson();

        if (!$jsonContent) {
            $this->error("Kredensial Firebase tidak ditemukan (Environment FIREBASE_CREDENTIALS_BASE64 maupun file JSON lokal).");
            return null;
        }

        $credentials = json_decode($jsonContent, true);
        $clientEmail = $credentials['client_email'] ?? null;
        $privateKey = $credentials['private_key'] ?? null;

        if (!$clientEmail || !$privateKey) {
            $this->error("Isi file/kredensial JSON Service Account tidak valid.");
            return null;
        }

        $now = time();
        $header = $this->base64UrlEncode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = $this->base64UrlEncode(json_encode([
            'iss' => $clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'exp' => $now + 3600,
            'iat' => $now,
        ]));

        $signatureInput = "{$header}.{$payload}";
        openssl_sign($signatureInput, $signature, $privateKey, 'SHA256');
        $base64UrlSignature = $this->base64UrlEncode($signature);

        $jwt = "{$signatureInput}.{$base64UrlSignature}";

        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        return $response->json('access_token');
    }

    private function sendFcmPush($fcmToken, $title, $body)
    {
        if (empty($fcmToken)) {
            $this->warn("Token FCM kosong, notifikasi dilewati.");
            return;
        }

        try {
            $accessToken = $this->getGoogleAccessToken();

            if (!$accessToken) {
                $this->error("Gagal membuat Google Access Token.");
                return;
            }

            $jsonContent = json_decode($this->getCredentialsJson(), true);
            $projectId = $jsonContent['project_id'] ?? null;

            $payload = [
                'message' => [
                    'token' => $fcmToken,
                    'notification' => [
                        'title' => (string) $title,
                        'body' => (string) $body,
                    ],
                    'android' => [
                        'priority' => 'HIGH',
                        'notification' => [
                            'channel_id' => 'her_space_channel_v7',
                            'sound' => 'herspace',
                            'default_sound' => false,
                            'notification_priority' => 'PRIORITY_MAX',
                        ],
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'sound' => 'herspace.wav',
                            ],
                        ],
                    ],
                ],
            ];

            $response = Http::withToken($accessToken)
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", $payload);

            if ($response->successful()) {
                $this->info("Notifikasi berhasil dikirim ke HP!");
            } else {
                $this->error("Gagal kirim FCM: " . $response->body());
            }

        } catch (\Exception $e) {
            $this->error("FCM Push Error: " . $e->getMessage());
            Log::error('FCM Push Error: ' . $e->getMessage());
        }
    }
}