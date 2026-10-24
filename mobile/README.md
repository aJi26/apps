# Her Space mobile setup

Run the Flutter app against the Laravel API:

```powershell
flutter run --dart-define=HER_SPACE_API_URL=http://10.0.2.2:8000/api
```

For a physical device, replace `10.0.2.2` with the reachable LAN address of the machine running Laravel.

Run the profile avatar migrations from the Laravel backend before using profile setup or avatar upload:

```powershell
cd backend
php artisan migrate
```
