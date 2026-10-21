<?php

namespace Tests\Feature;

use App\Models\AdminRole;
use App\Models\User;
use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class AdminMonitorTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        if (! extension_loaded('pdo_sqlite')) {
            $this->markTestSkipped('The PDO SQLite extension is required for these database tests.');
        }

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.database' => ':memory:',
        ]);

        $this->artisan('migrate');
    }

    public function test_non_admin_cannot_open_the_monitor(): void
    {
        $this->actingAs(User::factory()->create())
            ->get(route('admin.dashboard'))
            ->assertForbidden();
    }

    public function test_admin_receives_live_dashboard_data(): void
    {
        $admin = User::factory()->create(['name' => 'Monitor Admin']);
        AdminRole::create([
            'user_id' => $admin->id,
            'role' => 'super_admin',
        ]);

        $this->actingAs($admin)
            ->get(route('admin.dashboard'))
            ->assertOk()
            ->assertInertia(fn (Assert $page) => $page
                ->component('Admin/Overview')
                ->where('stats.totalUsers', 1)
                ->where('adminName', 'Monitor Admin')
                ->has('upcomingBirthdays', 0));
    }

    public function test_admin_login_rejects_a_regular_user(): void
    {
        $user = User::factory()->create();

        $this->post(route('admin.login.submit'), [
            'email' => $user->email,
            'password' => 'password',
        ])->assertSessionHasErrors('email');

        $this->assertGuest();
    }
}
