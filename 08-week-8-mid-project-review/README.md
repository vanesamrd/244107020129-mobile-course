# Myventory

Smart Inventory untuk UMKM dan cafe. Aplikasi mobile berbasis Flutter untuk memantau stok produk, prediksi kebutuhan, dan restock.

## Laporan perubahan: halaman login

Branch: `develop` → `main`

### Ringkasan

Menambahkan halaman login sebagai pintu masuk aplikasi. Sebelumnya aplikasi langsung membuka dashboard. Sekarang pengguna harus login dulu, dan bisa keluar lewat tombol logout di halaman Profile.

Autentikasi masih **mock** (data demo di dalam kode), belum terhubung ke backend.

### Fitur

- Form login dengan field email dan password
- Validasi input:
  - Email wajib diisi dan harus berformat valid
  - Password wajib diisi, minimal 6 karakter
- Tombol tampilkan/sembunyikan password
- Indikator loading saat proses masuk
- Pesan error (SnackBar) jika email atau password salah
- Tombol Logout di halaman Profile dengan dialog konfirmasi
- Tampilan mengikuti tema aplikasi (`AppTheme`), tanpa dependency baru

### Akun demo

| Email | Password |
| --- | --- |
| `admin@myventory.com` | `admin123` |

### File yang diubah

| File | Perubahan |
| --- | --- |
| `lib/pages/auth/login_page.dart` | **Baru.** Halaman login (form, validasi, loading, error) |
| `lib/app.dart` | `MyventoryApp` menjadi stateful dan menyimpan status login. `AppShell` menerima callback `onLogout` |
| `lib/pages/profile/profile_page.dart` | Menambah menu Logout dan dialog konfirmasi |
| `test/widget_test.dart` | Menambah langkah login sebelum memeriksa isi dashboard |

### Alur

```
LoginPage  --(email & password valid)-->  AppShell (Dashboard, Products, Prediction, Profile)
    ^                                              |
    +-------------- Logout (Profile) --------------+
```

### Cara menjalankan

```bash
flutter pub get
flutter run
```

Masuk dengan akun demo di atas.

### Cara menguji

```bash
flutter analyze
flutter test
```

### Catatan dan rencana lanjutan

- Status login hanya disimpan di memori. Menutup aplikasi akan mengembalikan ke halaman login.
- Data produk (`InventoryStore`) di-reset setiap kali login ulang karena `AppShell` dibuat ulang.
- Langkah berikutnya: ganti logika di `_submit()` pada `login_page.dart` dengan autentikasi sungguhan (misalnya Firebase Auth atau REST API), dan simpan sesi dengan secure storage.