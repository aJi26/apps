<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        \App\Console\Commands\SendDailyReminders::class,
    ];

    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // 1. Check-in Reminder setiap jam 07:00 Pagi
        $schedule->command('reminders:send checkin')
        ->dailyAt('15:00')
        ->timezone('Asia/Jakarta');

        // 2. Birthday Wishes setiap jam 00:00 Pagi
        $schedule->command('reminders:send birthday')
        ->dailyAt('00:00')
        ->timezone('Asia/Jakarta');

        // 3. Goals Reminder setiap jam 13:00 Siang
        $schedule->command('reminders:send goals')
        ->dailyAt('13:00')
        ->timezone('Asia/Jakarta');

        // 4. Finance Reminder setiap jam 19:00 Malam
        $schedule->command('reminders:send finance')
        ->dailyAt('19:00')
        ->timezone('Asia/Jakarta');
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}