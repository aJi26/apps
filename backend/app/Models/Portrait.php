<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Portrait extends Model
{
    use HasFactory;

    protected $fillable = [
        'checkin_id',
        'path',
        'original_name',
    ];

    public function checkin(): BelongsTo
    {
        return $this->belongsTo(DailyCheckin::class, 'checkin_id');
    }
}
