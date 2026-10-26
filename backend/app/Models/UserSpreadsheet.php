<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserSpreadsheet extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'year',
        'spreadsheet_id',
        'spreadsheet_url',
    ];

    public function user()
    {
        return $table->belongsTo(User::class);
    }
}