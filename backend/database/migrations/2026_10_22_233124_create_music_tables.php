<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Tabel Lagu & Playlist Komunitas Pilihan Admin
        Schema::create('music_tracks', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('artist')->nullable();
            $table->string('genre')->nullable(); // Pop, Hipdut, RnB, Soft Chill, dll.
            $table->string('mood')->nullable();  // Happy, Sad, Calm, Anxious, dll.
            $table->text('url_spotify')->nullable();
            $table->text('url_youtube')->nullable();
            $table->boolean('is_community_playlist')->default(false);
            $table->timestamps();
        });

        // 2. Tabel Folder Playlist Pribadi Pengguna
        Schema::create('user_playlists', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title');
            $table->string('cover_color')->default('#E8F5E9');
            $table->timestamps();
        });

        // 3. Tabel Item Lagu di Playlist Pribadi
        Schema::create('user_playlist_tracks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_playlist_id')->constrained('user_playlists')->onDelete('cascade');
            $table->string('title');
            $table->string('artist')->default('Unknown');
            $table->text('url');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_playlist_tracks');
        Schema::dropIfExists('user_playlists');
        Schema::dropIfExists('music_tracks');
    }
};