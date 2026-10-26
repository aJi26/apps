FROM php:8.2-cli

# Install dependency PostgreSQL dan tools pendukung
RUN apt-get update && apt-get install -y \
    libpq-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-install pdo pdo_pgsql

# Ambil composer dari image resmi
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

# Install paket Laravel
RUN composer install --no-dev --optimize-autoloader

# Buat folder jika belum ada dan atur permission
RUN mkdir -p storage/framework/views storage/framework/sessions storage/framework/cache bootstrap/cache \
    && chmod -R 777 storage bootstrap/cache

# Jalankan migrasi database lalu start server
CMD php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=$PORT