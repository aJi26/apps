<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Portrait extends Model
{
    use HasFactory;

    protected $fillable = [
        'checkin_id',
        'path',
        'original_name',
    ];
}
