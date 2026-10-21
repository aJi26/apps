<?php

namespace Database\Seeders;

use App\Models\AdminRole;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $email = env('ADMIN_EMAIL', 'admin@herspace.com');
        $password = env('ADMIN_PASSWORD', 'admin123');

        if (! $email || ! $password) {
            throw new RuntimeException('Set ADMIN_EMAIL and ADMIN_PASSWORD before creating an administrator.');
        }

        $user = User::updateOrCreate(
            ['email' => $email],
            [
                'name' => env('ADMIN_NAME', 'Her Space Admin'),
                'password' => Hash::make($password),
                'is_active' => true,
            ]
        );

        if (! $user->is_active) {
            throw new RuntimeException('The configured administrator account is inactive.');
        }

        AdminRole::firstOrCreate([
            'user_id' => $user->id,
            'role' => 'super_admin',
        ]);
    }
}
