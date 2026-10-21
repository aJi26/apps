# HER SPACE
## Product Requirements Document (PRD)

**Versi:** 1.0 — Draft
**Tanggal:** 21 Oktober 2026  
**Platform:** Android APK + Responsive Web Monitor
**Prioritas:** MVP (Minimum Viable Product)

---

## 1. Product Vision

Her Space adalah aplikasi personal yang dirancang sebagai ruang digital untuk mencatat keseharian, mengenali diri sendiri, menyimpan tujuan, mengelola wishlist, dan mendokumentasikan momen melalui foto Potret harian.

Her Space memiliki dua antarmuka yang terhubung ke satu backend:

1. **Her Space APK:** aplikasi Android untuk pengguna utama.
2. **Her Space Monitor:** dashboard web untuk administrator memantau pengguna, aktivitas, tujuan, hasil kuis, dan foto Potret yang tersimpan.

Kedua platform menggunakan backend Laravel dan database PostgreSQL yang sama agar data tersinkronisasi.

## 2. Product Objectives

- Menyediakan pengalaman personal yang hangat, sederhana, dan mudah digunakan.
- Memungkinkan pengguna memasuki aplikasi dengan satu tombol setelah autentikasi awal.
- Menerapkan Potret harian sebagai gerbang wajib sebelum mengakses dashboard.
- Menyimpan data pengguna secara terpusat agar dapat diakses melalui platform yang berwenang.
- Menyediakan dashboard monitoring dengan informasi yang relevan bagi administrator.
- Menjaga privasi catatan personal dan konten sensitif.
- Mengutamakan arsitektur yang mudah dipelajari, dikembangkan, dan dipelihara.

## 3. Target Users

### 3.1 Primary User

Pengguna utama yang menggunakan Her Space APK untuk:

- Melakukan Potret harian.
- Melihat dashboard personal.
- Mengisi kuis self-discovery.
- Mengelola goals dan wishlist.
- Menulis notes.
- Mengakses musik, rekomendasi, dan randomizer.
- Mengatur preferensi.
- Mengakses Secret Message.

### 3.2 Administrator

Administrator menggunakan Her Space Monitor melalui browser desktop atau ponsel untuk:

- Melihat daftar akun yang terdaftar.
- Melihat ringkasan aktivitas.
- Membuka detail pengguna.
- Memantau foto Potret.
- Melihat informasi goals dan hasil kuis.
- Memeriksa riwayat aktivitas yang dicatat aplikasi.
- Melihat ulang tahun pengguna yang akan datang.

Administrator hanya boleh mengakses data sesuai peran dan izin yang ditetapkan. Monitoring tidak berarti mengakses aktivitas pengguna di luar aplikasi.

## 4. Her Space Mobile App — Functional Requirements

### 4.1 Splash Screen

- Menampilkan identitas dan logo Her Space.
- Menjadi layar pembuka sebelum Welcome Screen.
- Mengikuti identitas visual utama aplikasi.

### 4.2 Welcome Screen dan One-Click Entry

Welcome Screen memiliki satu tombol utama:

**Enter Her Space ♡**

Saat tombol ditekan, aplikasi memeriksa:

- Validitas sesi login.
- Kelengkapan profil.
- Status Potret untuk tanggal berjalan.

Alur navigasi:

- Sesi belum tersedia atau tidak valid → autentikasi.
- Profil belum lengkap → Profile Setup.
- Profil lengkap, Potret hari ini belum selesai → Daily Potret.
- Potret hari ini sudah selesai → Home Dashboard.

Sesi disimpan secara aman sehingga pengguna tidak perlu login ulang setiap kali membuka aplikasi selama sesi masih valid.

### 4.3 Registration dan Authentication

- Pengguna dapat membuat akun dan melakukan autentikasi.
- Sistem menyimpan identitas pengguna secara konsisten di backend.
- Laravel menyediakan endpoint API untuk kebutuhan autentikasi aplikasi Flutter.
- Token API dikelola dengan mekanisme autentikasi yang aman, misalnya Laravel Sanctum.
- Pengguna dapat logout.
- Sesi kedaluwarsa harus ditangani dengan meminta autentikasi kembali.

### 4.4 Profile Setup

- Pengguna baru melengkapi profil yang diperlukan.
- Profil disimpan di PostgreSQL dan terhubung ke akun autentikasi.
- Tanggal lahir (`birthday`) diminta saat setup profil jika fitur ulang tahun diaktifkan.
- Pengguna tidak perlu mengulang pengaturan profil setiap kali membuka aplikasi.
- Sistem memvalidasi tanggal lahir dan menangani tanggal yang tidak valid.

### 4.5 Mandatory Daily Potret

Potret adalah fitur wajib yang harus diselesaikan sebelum pengguna memasuki dashboard pada hari yang bersangkutan.

**Aturan utama:**
- Satu Potret berhasil untuk setiap pengguna pada setiap tanggal kalender.
- Potret tidak perlu diulang apabila sudah berhasil diselesaikan pada hari yang sama.
- Ketika tanggal berganti dan belum ada Potret untuk hari tersebut, pengguna wajib melakukannya lagi.
- Tidak tersedia tombol “Skip for today”.
- Kamera hanya diaktifkan melalui alur Potret di dalam aplikasi.
- Pengguna tidak dapat memilih foto dari galeri.
- Foto tidak dikirim secara diam-diam.

**Alur Potret:**

1. Aplikasi meminta izin kamera jika belum diberikan.
2. Pengguna mengambil foto melalui kamera aplikasi.
3. Aplikasi menampilkan preview.
4. Pengguna memilih Retake atau Send.
5. Jika memilih Retake, kamera dibuka kembali.
6. Jika memilih Send, foto diunggah melalui API Laravel.
7. Backend memvalidasi permintaan dan menyimpan foto beserta metadata check-in.
8. Check-in dinyatakan selesai setelah backend mengonfirmasi penyimpanan berhasil.
9. Aplikasi membuka Home Dashboard.

**Penanganan kegagalan:**
- Jika kamera tidak diizinkan, aplikasi menampilkan instruksi untuk mengaktifkannya.
- Jika upload gagal atau koneksi terputus, pengguna tetap berada pada alur Potret.
- Aplikasi menyediakan opsi mencoba mengirim ulang.
- Sistem tidak membuat check-in sukses palsu ketika foto belum tersimpan.
- Permintaan berulang tidak boleh menghasilkan check-in ganda untuk tanggal yang sama.

Status Potret diperiksa saat aplikasi dibuka dan ketika aplikasi kembali dari background. Pemeriksaan tanggal menggunakan satu zona waktu aplikasi yang konsisten, dengan `Asia/Jakarta` sebagai default yang diusulkan.

### 4.6 Home Dashboard

Dashboard merupakan halaman utama setelah Potret selesai.

Dashboard menyediakan akses ke fitur personal:

- Self-Discovery Quiz.
- Goals.
- Wishlist.
- Notes.
- Music, Recommendations & Randomizer.
- Preferences.
- Secret Message.

Susunan navigasi dan prioritas visual ditentukan melalui proses desain mockup.

### 4.7 Self-Discovery Quiz

- Pengguna dapat mengikuti kuis yang tersedia.
- Sistem menyimpan jawaban dan hasil kuis.
- Riwayat percobaan dapat dicatat jika diperlukan.
- Informasi hasil kuis yang ditampilkan pada dashboard admin mengikuti aturan akses yang disepakati.

### 4.8 Goals

- Pengguna dapat membuat, melihat, memperbarui, dan menghapus goals.
- Sistem menyimpan status dan tanggal yang relevan.
- Dashboard admin dapat menampilkan ringkasan goals sesuai izin yang ditetapkan.

### 4.9 Wishlist

- Pengguna dapat menambah, melihat, memperbarui, dan menghapus item wishlist.
- Data terhubung ke akun pengguna.
- Visibilitas di dashboard admin ditentukan berdasarkan kebijakan privasi produk.

### 4.10 Notes

- Pengguna dapat menulis dan mengelola catatan personal.
- Konten notes bersifat privat secara default.
- Dashboard admin tidak menampilkan isi notes secara otomatis.
- Jika diperlukan, fitur berbagi harus dirancang sebagai mekanisme eksplisit dan memiliki izin yang jelas.

### 4.11 Music, Recommendations & Randomizer

- Menyediakan akses ke fitur musik dan rekomendasi.
- Menyediakan randomizer untuk membantu pengguna memilih aktivitas atau opsi yang tersedia.
- Konten dan mekanisme rekomendasi ditentukan pada tahap desain dan implementasi.

### 4.12 Preferences

- Pengguna dapat mengatur preferensi yang didukung aplikasi.
- Preferensi disimpan di backend dan dimuat kembali ketika aplikasi dibuka.

### 4.13 Secret Message

- Menyediakan ruang untuk pesan personal.
- Konten bersifat privat secara default.
- Isi pesan tidak boleh ditampilkan otomatis pada dashboard monitoring tanpa keputusan produk dan izin yang eksplisit.

## 5. Her Space Monitor — Functional Requirements

### 5.1 Admin Authentication

- Administrator wajib login.
- Hak administrator diperiksa di backend Laravel.
- Pengguna biasa tidak boleh memperoleh hak admin hanya dengan mengubah antarmuka atau request dari browser.
- Endpoint admin dilindungi middleware dan kebijakan otorisasi.

### 5.2 Overview Dashboard

Dashboard menampilkan ringkasan informasi yang relevan, seperti:

- Jumlah akun terdaftar.
- Aktivitas terbaru yang tercatat.
- Ringkasan Potret harian.
- Ringkasan goals.
- Ringkasan kuis.
- **Upcoming Birthdays:** daftar pengguna yang ulang tahunnya paling dekat.

Semua statistik harus berasal dari data aktual database, bukan angka statis.

**Aturan Upcoming Birthdays:**
- Gunakan tanggal dan bulan lahir untuk menghitung ulang tahun terdekat.
- Tampilkan nama pengguna, tanggal ulang tahun, dan jumlah hari menuju ulang tahun jika relevan.
- Ulang tahun yang sudah lewat pada tahun berjalan dihitung untuk tahun berikutnya.
- Jika tanggal lahir lengkap disimpan, tahun lahir dapat ditampilkan di User Detail; Overview tidak perlu menampilkan umur kecuali dibutuhkan.
- Penanganan tanggal 29 Februari harus ditentukan secara konsisten untuk tahun non-kabisat.

### 5.3 User List

- Menampilkan daftar akun yang terdaftar di Her Space.
- Menampilkan informasi dasar yang diperlukan untuk mengenali akun.
- Mendukung pencarian atau penyaringan jika diperlukan.
- Setiap pengguna dapat dibuka untuk melihat detailnya.
- Tanggal dan bulan ulang tahun boleh ditampilkan sebagai informasi tambahan, jika tidak membuat tampilan mobile terlalu padat.
- Daftar pengguna pada layar kecil harus menggunakan kartu responsif, bukan tabel desktop yang menyempit.

### 5.4 User Detail

Halaman detail menampilkan informasi yang diizinkan, seperti:

- Informasi profil.
- **Tanggal lahir lengkap** (tanggal, bulan, dan tahun).
- Tanggal bergabung.
- Waktu login terakhir, jika dicatat secara andal.
- Status Potret hari ini.
- Riwayat Potret.
- Ringkasan aktivitas dalam aplikasi.
- Goals dan statusnya.
- Riwayat serta hasil kuis.
- Informasi lain yang telah ditetapkan sebagai data monitoring.

Data sensitif, termasuk isi notes dan Secret Message, tetap privat secara default.

### 5.5 Potret Gallery

- Menampilkan foto Potret yang berhasil diunggah.
- Foto dapat dikelompokkan berdasarkan pengguna dan tanggal atau bulan.
- Menyediakan tampilan daftar/thumbnail dan tampilan detail foto.
- Metadata foto, seperti tanggal check-in dan waktu upload, ditampilkan sesuai ketersediaan data.
- Administrator dapat membuka foto lebih besar jika memiliki izin.
- Foto hanya dapat diakses oleh pengguna yang memiliki izin.
- URL dan lokasi penyimpanan foto tidak boleh membuka akses publik yang tidak disengaja.

### 5.6 Activity History

- Menampilkan aktivitas yang secara eksplisit dicatat oleh aplikasi.
- Setiap catatan aktivitas memiliki pengguna, jenis aktivitas, dan waktu kejadian yang relevan.
- Aktivitas dapat difilter berdasarkan kategori, seperti check-in, quiz, dan goals.
- Riwayat dapat digunakan untuk membantu administrator memahami penggunaan aplikasi.
- Sistem tidak melacak aktivitas perangkat atau aktivitas di luar aplikasi.

### 5.7 Goals dan Quiz Monitoring

- Administrator dapat melihat ringkasan goals dan statusnya.
- Administrator dapat melihat hasil kuis sesuai kebijakan akses.
- Tampilan harus membedakan ringkasan dan konten personal yang tidak boleh dibuka.

### 5.8 Admin Profile dan Settings

- Administrator dapat melihat atau memperbarui profilnya sesuai kebutuhan.
- Pengaturan dapat mencakup keamanan akun, notifikasi, dan preferensi tampilan.
- Fitur yang belum diimplementasikan tidak boleh ditampilkan seolah-olah berfungsi.

### 5.9 Mobile Navigation dan Responsive UI

- Web Monitor dirancang dengan pendekatan **mobile-first**.
- Navigasi utama harus nyaman digunakan pada layar ponsel.
- Navigasi bawah dapat digunakan untuk bagian utama, seperti Overview, Users, Potret, Activity, dan Settings.
- Halaman detail dapat memakai tab atau menu sekunder yang tetap mudah digunakan di layar kecil.
- Tabel desktop diubah menjadi kartu atau daftar responsif pada layar mobile.
- Kontrol interaktif harus memiliki area sentuh yang nyaman dan label yang jelas.
- Tampilan desktop tetap didukung tanpa membuat layout mobile bergantung pada tabel lebar.

## 6. Core User Flows

### 6.1 First-Time User

Welcome Screen → Enter Her Space ♡ → Registration/Authentication → Profile Setup → Daily Potret → Preview → Send → Server confirms upload → Home Dashboard.

### 6.2 Returning User, Potret Belum Selesai

Welcome Screen → Enter Her Space ♡ → Session Validation → Daily Potret → Preview → Send → Upload Confirmed → Home Dashboard.

### 6.3 Returning User, Potret Sudah Selesai Hari Ini

Welcome Screen → Enter Her Space ♡ → Session Validation → Check-In Validation → Home Dashboard.

### 6.4 Potret Hari Berikutnya

Ketika tanggal kalender aplikasi berganti, aplikasi memeriksa status Potret terbaru. Jika belum ada Potret yang berhasil untuk tanggal tersebut, pengguna diarahkan ke alur Mandatory Daily Potret.

### 6.5 Admin Monitoring

Admin Login → Overview Dashboard → User List → Select User → User Detail → Potret Gallery, Goals, Quiz Results, atau Activity History.

### 6.6 Birthday Monitoring

Admin membuka Overview → melihat Upcoming Birthdays → memilih pengguna → membuka User Detail untuk melihat tanggal lahir lengkap dan informasi profil lainnya.

## 7. Technical Architecture

### 7.1 Technology Stack

| Layer | Teknologi |
|---|---|
| Android application | Flutter + Dart |
| Web frontend | Vue.js |
| Web language | TypeScript (direkomendasikan) atau JavaScript |
| Web-backend integration | Inertia.js |
| Web styling | Tailwind CSS |
| Backend framework | Laravel |
| Database | PostgreSQL |
| Mobile API authentication | Laravel Sanctum atau mekanisme token API yang sesuai |
| Photo storage | Laravel Storage dengan akses privat |
| Source code management | GitHub |
| AI coding assistant | Gemini |

Pilih TypeScript atau JavaScript sebagai pendekatan utama web agar struktur kode konsisten. TypeScript direkomendasikan untuk membantu pemeriksaan tipe data.

### 7.2 Architecture Overview

**A. Her Space APK**
- Dibangun menggunakan Flutter dan Dart.
- Berkomunikasi dengan Laravel melalui REST API menggunakan HTTPS.
- Menggunakan API untuk autentikasi, profil, Potret, goals, wishlist, kuis, dan fitur lain.
- Tidak mengakses PostgreSQL secara langsung.

**B. Her Space Monitor**
- Dibangun menggunakan Vue.js dan Inertia.js.
- Menggunakan TypeScript atau JavaScript untuk kode frontend.
- Laravel menangani routing web, autentikasi, otorisasi, logika bisnis, dan pengambilan data.
- Inertia.js menghubungkan Laravel dengan halaman Vue tanpa mengharuskan pembuatan SPA terpisah menggunakan backend API untuk seluruh navigasi web.

**C. Shared Backend**
- Laravel menyediakan logika bisnis dan akses data terpusat.
- PostgreSQL menyimpan data terstruktur.
- Laravel Storage mengelola penyimpanan file foto.
- Aturan akses dan validasi penting dijalankan di backend.

### 7.3 Architecture Diagram

```text
Her Space APK
Flutter + Dart
       |
       | HTTPS / REST API
       v
+--------------------------+
|      Laravel Backend     |
| Authentication           |
| Authorization            |
| Business Logic            |
| Photo Upload              |
| API + Web Routes          |
+--------------------------+
       |
       +-----------> PostgreSQL
       |
       +-----------> Private File Storage
       ^
       |
       | Inertia.js
       |
Her Space Monitor
Vue.js + TypeScript/JavaScript
Tailwind CSS
```

### 7.4 Database

PostgreSQL menjadi database utama untuk data terstruktur. Skema dan relasi dirancang melalui migration Laravel.

Data utama yang perlu disimpan meliputi:

- Akun autentikasi.
- Profil pengguna, termasuk tanggal lahir jika dikumpulkan.
- Check-in harian.
- Metadata foto Potret.
- Goals.
- Wishlist.
- Notes.
- Data kuis dan jawaban.
- Preferensi pengguna.
- Activity logs.
- Role dan izin administrator.

### 7.5 Photo Storage

- Foto Potret disimpan melalui Laravel Storage.
- Database menyimpan metadata dan referensi lokasi file.
- Foto harus berada pada penyimpanan privat.
- Pengambilan foto dilakukan melalui endpoint atau URL bertanda tangan yang memiliki masa berlaku, setelah otorisasi berhasil.
- Strategi backup dan penghapusan foto harus ditetapkan sebelum produksi.

### 7.6 Deployment

- Aplikasi Android didistribusikan sebagai APK pada tahap awal.
- Web Monitor diakses melalui browser desktop maupun mobile.
- Backend Laravel, database PostgreSQL, dan penyimpanan file harus tersedia pada lingkungan deployment yang sesuai.
- Biaya operasional bergantung pada layanan hosting, kapasitas penyimpanan, trafik, dan backup yang dipilih.
- Penggunaan paket gratis dapat dipertimbangkan, tetapi tidak menjamin layanan selalu gratis atau selalu aktif.

## 8. Initial Database Entities

Struktur berikut adalah rancangan awal, bukan skema final.

| Entity | Tanggung jawab |
|---|---|
| users | Identitas akun dan autentikasi |
| profiles | Informasi profil, termasuk tanggal lahir jika digunakan |
| daily_checkins | Status check-in berdasarkan pengguna dan tanggal |
| portraits | Metadata dan referensi file Potret |
| goals | Tujuan dan statusnya |
| wishlists | Item wishlist |
| notes | Catatan personal |
| quizzes | Definisi kuis |
| quiz_attempts | Percobaan dan hasil kuis |
| quiz_answers | Jawaban pengguna, jika diperlukan |
| user_preferences | Preferensi pengguna |
| activity_logs | Riwayat aktivitas aplikasi |
| admin_roles | Peran atau penetapan hak administrator |

Catatan implementasi:

- `daily_checkins` harus memiliki aturan unik untuk kombinasi pengguna dan tanggal check-in.
- Operasi check-in dan penyimpanan metadata harus dirancang agar tidak meninggalkan status sukses ketika penyimpanan foto gagal.
- Relasi data menggunakan foreign key dan aturan penghapusan yang sesuai.
- Struktur akhir disesuaikan dengan kebutuhan relasional serta migration Laravel.
- Kolom tanggal lahir harus dapat bernilai kosong jika pengguna belum memberikannya atau produk tidak mewajibkannya.

## 9. Security & Privacy

### 9.1 Authentication and Authorization

- Semua endpoint yang memerlukan login harus memvalidasi autentikasi.
- Hak akses admin harus diverifikasi di backend.
- Hak akses pengguna dibatasi pada data yang sesuai dengan akun dan kebijakannya.
- API token dan sesi harus dikelola dengan aman.

### 9.2 Database Security

- PostgreSQL tidak diekspos langsung ke frontend.
- Validasi data dilakukan di backend.
- Query dan operasi database harus menggunakan mekanisme yang aman.
- Kredensial database hanya disimpan di konfigurasi server atau environment secrets.

### 9.3 Photo Privacy

- Pengguna mengetahui bahwa foto yang dikirim melalui Potret disimpan dan dapat dilihat administrator yang berwenang.
- Kamera tidak boleh berjalan diam-diam di background.
- Aplikasi tidak menyediakan pemilihan foto dari galeri untuk alur Potret wajib.
- Foto tidak dapat diakses publik secara default.

### 9.4 Private Content

- Notes dan Secret Message privat secara default.
- Dashboard admin tidak otomatis mendapat akses ke seluruh konten personal.
- Aktivitas monitoring dibatasi pada aktivitas yang memang dicatat aplikasi.
- Kebijakan akses, retensi, dan penghapusan data harus jelas.

### 9.5 Birthday Privacy

- Tanggal lahir dikumpulkan dengan penjelasan yang jelas kepada pengguna.
- Tanggal lahir lengkap hanya ditampilkan kepada pihak yang memiliki izin.
- Overview cukup menampilkan nama, tanggal/bulan ulang tahun, dan hitung mundur jika diperlukan.
- Jangan menampilkan umur atau tahun lahir pada ringkasan jika tidak dibutuhkan.

### 9.6 Secrets Management

- Jangan menaruh kredensial PostgreSQL, private storage credentials, atau secret server di aplikasi Flutter maupun bundle frontend.
- Gunakan environment variables atau secret management pada server.
- Endpoint upload harus memvalidasi autentikasi, tipe file, ukuran file, dan batasan permintaan.

## 10. Non-Functional Requirements

### Usability
- Aplikasi Android responsif terhadap ukuran layar perangkat.
- Alur masuk sederhana dan konsisten.
- Status loading, error, dan keberhasilan upload harus jelas.
- Web Monitor dapat digunakan pada desktop dan browser ponsel.

### Reliability
- Check-in hanya berhasil setelah penyimpanan terkonfirmasi.
- Aplikasi menangani jaringan terputus dan kegagalan upload.
- Status Potret diverifikasi oleh backend, bukan hanya jam perangkat.
- Operasi berulang tidak menghasilkan data check-in ganda.

### Performance
- Data dashboard dimuat secara efisien.
- Foto menggunakan strategi penyimpanan dan pemuatan yang sesuai.
- Halaman monitoring membatasi jumlah data yang dimuat sekaligus bila diperlukan.

### Maintainability
- Backend, API, web frontend, dan aplikasi Android memiliki struktur kode yang terorganisasi.
- Perubahan skema dilakukan menggunakan migration.
- Kontrak API dijaga konsisten antara Laravel dan Flutter.

### Cost
- Mengutamakan pilihan yang sesuai untuk MVP.
- Memantau biaya hosting, database, penyimpanan foto, trafik, dan backup.
- Menyediakan strategi untuk mengendalikan pertumbuhan penyimpanan.

## 11. MVP Scope

### Included
- Registrasi dan autentikasi.
- Penyimpanan sesi secara aman.
- Profile Setup.
- Mandatory Daily Potret.
- Preview, Retake, dan Send.
- Validasi keberhasilan upload oleh backend.
- Home Dashboard.
- Self-Discovery Quiz.
- Goals.
- Wishlist.
- Notes.
- Music, Recommendations & Randomizer.
- Preferences.
- Secret Message.
- Admin Login.
- Overview Dashboard.
- Upcoming Birthdays.
- User List dan User Detail.
- Potret Gallery.
- Activity History.
- Goals dan Quiz Monitoring.
- Admin Profile dan Settings dasar.
- Navigasi web mobile-first.
- Backend Laravel dan database PostgreSQL.
- Web Monitor dengan Vue + Inertia.js.
- APK Android dengan Flutter.

### Excluded from initial MVP
- Publikasi ke Play Store jika distribusi APK langsung sudah mencukupi.
- Monitoring aktivitas di luar aplikasi.
- Kamera yang aktif diam-diam atau pengambilan foto tanpa tindakan pengguna.
- Akses otomatis administrator ke seluruh isi notes atau Secret Message.
- Fitur real-time kompleks yang belum diperlukan.
- Integrasi layanan eksternal berbayar yang belum disepakati.

## 12. Acceptance Criteria

### User App
1. Pengguna baru dapat mendaftar dan menyelesaikan Profile Setup.
2. Pengguna yang memiliki sesi valid dapat masuk melalui tombol Enter Her Space ♡.
3. Pengguna dengan profil lengkap tidak dapat melewati Potret jika belum menyelesaikannya pada tanggal berjalan.
4. Tidak tersedia opsi Skip for today.
5. Pengguna dapat mengambil foto hanya melalui kamera di dalam alur Potret.
6. Pengguna dapat meninjau foto sebelum memilih Retake atau Send.
7. Dashboard tidak dapat diakses sebelum upload Potret dikonfirmasi berhasil.
8. Kegagalan upload tidak menandai check-in sebagai selesai.
9. Pengguna yang sudah berhasil Potret hari itu tidak perlu mengulanginya saat membuka aplikasi lagi pada hari yang sama.
10. Saat tanggal berganti, aplikasi memeriksa kembali status Potret.

### Admin Monitor
11. Administrator dapat melihat akun terdaftar dan membuka detail pengguna sesuai hak akses.
12. Foto Potret yang tersimpan dapat ditampilkan di Potret Gallery oleh administrator yang berwenang.
13. Notes dan Secret Message tetap privat secara default.
14. Upcoming Birthdays menghitung ulang tahun terdekat secara benar berdasarkan tanggal dan bulan.
15. User Detail menampilkan tanggal lahir lengkap jika tersedia dan administrator berwenang.
16. User List tetap mudah digunakan di layar kecil dan mendukung pencarian jika diimplementasikan.
17. Navigasi utama dapat digunakan pada browser mobile.
18. Tampilan desktop tetap didukung.
19. Pengguna biasa tidak dapat memperoleh akses administrator hanya dengan mengubah request atau antarmuka.

### Architecture
20. Laravel memvalidasi autentikasi dan otorisasi untuk akses data.
21. Aplikasi Android dan Web Monitor menggunakan backend serta database yang sama.
22. Check-in dan penyimpanan metadata tidak menghasilkan status sukses yang tidak konsisten.

## 13. Open Decisions Before Implementation

1. **Visual design:** warna, tipografi, ikon, layout, dan identitas visual final.
2. **Mobile navigation:** struktur tab, menu, dan urutan fitur dashboard.
3. **Quiz scoring:** pertanyaan, sistem penilaian, dan bentuk hasil.
4. **Admin user list:** kolom profil dan informasi ringkasan.
5. **Monitoring policy:** data apa saja yang terlihat oleh administrator.
6. **Photo retention:** durasi penyimpanan, kebijakan penghapusan, dan backup.
7. **Timezone:** zona waktu resmi untuk pergantian hari, dengan Asia/Jakarta sebagai usulan awal.
8. **Offline handling:** cara menangani upload gagal, retry, dan pemulihan koneksi.
9. **Deployment:** layanan hosting untuk Laravel, PostgreSQL, dan penyimpanan foto.
10. **Account management:** perubahan profil, penggantian password, dan penghapusan akun.
11. **Admin permissions:** apakah hanya ada satu administrator atau diperlukan beberapa level akses.
12. **Photo validation:** batas ukuran file, format gambar, dan kompresi.
13. **Birthday edge case:** aturan untuk tanggal lahir 29 Februari pada tahun non-kabisat.
14. **Birthday display:** apakah tanggal lahir diwajibkan atau opsional pada Profile Setup.

---

## 14. Product Principle

Her Space harus terasa seperti ruang personal yang hangat bagi pengguna, tetapi tetap memiliki backend yang terstruktur, keamanan yang memadai, serta mekanisme monitoring yang transparan.

**Prinsip arsitektur final:**
- Satu aplikasi Android berbasis Flutter.
- Satu web monitor berbasis Vue dan Inertia.js.
- Satu backend Laravel.
- Satu database PostgreSQL.
- Satu sistem penyimpanan foto yang dikontrol backend.

PRD ini menjadi dasar untuk merancang mockup, menentukan alur navigasi, menyusun struktur database, dan mengimplementasikan MVP secara bertahap.
