# 📱 Aplikasi Pelaporan Akademik

Aplikasi mobile untuk melaporkan pelanggaran akademik dengan sistem verifikasi admin berbasis web.

## 👥 Tim Pengembang

**Nama Tim:** Dream

**Ketua Kelompok:**
- Gede Rama Jayakusuma

**Anggota Tim:**
1. Dea Vaulina
2. Najwa Mar’atus Zahra
3. Tsaniyah Qurrota Akyunah Siregar
4. Andika Sandi Pranata
5. Agis Ikhlas Sifa
6. Firdaus Alfaridzi
7. I Komang Artayasa
8. M. Yunus naufal
9. Naufal Zaky Syahputr

---

## 📋 Deskripsi Proyek

Aplikasi Pelaporan Akademik adalah sistem pelaporan pelanggaran akademik yang terdiri dari:
- **Mobile App (Flutter)**: Aplikasi mobile untuk mahasiswa melaporkan pelanggaran akademik
- **Admin Panel (Laravel)**: Website admin untuk verifikasi dan pengelolaan laporan

### ✨ Fitur Utama

#### Mobile App:
- 🔐 **Dual Login System**
  - Login via email
  - Login dengan Google Sign-In
  - Dua metode akses: login saat membuat laporan atau login terlebih dahulu
- 📝 **Pelaporan**
  - Form lengkap dengan judul, deskripsi, kategori, dan tanggal kejadian
  - Kategori custom untuk pelanggaran lainnya
  - Upload foto/video bukti (maksimal 5 media)
  - Ambil foto/video langsung dari kamera
- 👤 **Profil Pengguna**
  - Sinkronisasi otomatis dengan akun login
  - Support foto profil dari Google atau upload manual
  - Edit profil (nama, email, telepon, NIM, jurusan)
- 📊 **Dashboard**
  - Statistik laporan (total, diproses, selesai, ditolak)
  - Berita terbaru
  - Akses cepat ke menu utama
- 🔔 **Notifikasi**
  - Update status laporan
  - Notifikasi sistem
- 📄 **Riwayat Laporan**
  - Filter berdasarkan status
  - Detail lengkap setiap laporan

#### Admin Panel:
- 🏠 Dashboard dengan statistik lengkap
- 📋 Manajemen laporan (review, approve, reject)
- 👥 Manajemen user
- 📂 Manajemen kategori
- 🔐 Role-based access (Admin & Super Admin)
- 📊 Database management tools

---

## 🛠️ Teknologi yang Digunakan

### Mobile App:
- **Framework**: Flutter 3.x
- **State Management**: StatefulWidget
- **Storage**: SharedPreferences
- **Authentication**: Google Sign-In
- **Media**: image_picker, video_player
- **UI**: Material Design

### Admin Panel:
- **Framework**: Laravel 11
- **Frontend**: Blade Templates, Tailwind CSS
- **Database**: MySQL
- **Authentication**: Laravel Sanctum

---

## 📦 Instalasi

### Prerequisites:
- Flutter SDK (3.0 atau lebih baru)
- Android Studio / VS Code
- PHP 8.2+
- Composer
- MySQL

### Setup Mobile App:

```bash
# Clone repository
git clone https://github.com/Rama200000/Dream.git
cd Dream

# Install dependencies
flutter pub get

# Konfigurasi Google Sign-In
# Edit android/app/google-services.json dengan credential Anda

# Run aplikasi
flutter run
```

### Setup Admin Panel:

```bash
# Masuk ke folder admin panel
cd admin_panel

# Install dependencies
composer install

# Copy environment file
cp .env.example .env

# Generate app key
php artisan key:generate

# Setup database di .env
DB_DATABASE=pelaporan_akademik
DB_USERNAME=root
DB_PASSWORD=

# Migrate dan seed database
php artisan migrate --seed

# Run server
php artisan serve
```

**Default Admin Login:**
- Email: admin@polinela.ac.id
- Password: admin123

---

## 📱 Screenshots

[Tambahkan screenshots aplikasi di sini]

---

## 🤝 Kontribusi

Proyek ini dikembangkan oleh Tim Dream untuk tugas akhir/project kampus.

---

## 📄 Lisensi

Proyek ini dikembangkan untuk keperluan akademik.

---

## 📞 Kontak

Untuk pertanyaan lebih lanjut, hubungi:
- **Email**: rama.jayakusuma@polinela.ac.id
- **GitHub**: [Rama200000](https://github.com/Rama200000)

---

## 🚀 Status Pengembangan

- ✅ Implementasi dual login system
- ✅ Integrasi SharedPreferences
- ✅ Sinkronisasi profil dengan akun
- ✅ Fitur upload media (foto/video)
- ✅ Admin panel dengan role management
- 🔄 Integrasi API Mobile ↔ Admin Panel (In Progress)
- 📅 Push notification (Planned)
