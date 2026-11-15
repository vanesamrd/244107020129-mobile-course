# Week 12 – Testing & Quality Assurance

Nama : Vanesa Mardiana Putri
NIM : 244107020129
Kelas : TI-3G
Absen : 25

## 1. Ringkasan

Praktikum Week 12 diterapkan pada aplikasi **Notes App** dari project Week 10 (`10-week-10-ai-feature-integration`), bukan dengan membuat aplikasi baru. Folder Week 12 ini di-scaffold sebagai proyek Flutter agar struktur praktikum lengkap, tetapi seluruh kode pengujian dan eksekusinya berada di project Week 10 karena test mengimpor package `notes_app`.

Fitur yang diuji disesuaikan dengan fitur asli aplikasi, yaitu catatan lokal SQLite, pencarian judul, tambah catatan, hapus catatan, serta layanan AI yang sudah ada. Karena aplikasi tidak memiliki entitas tugas/task, konsep `TaskRepository` tidak dipaksakan. Konsep tersebut diadaptasi menjadi `NotesRepository` dan pengujian notifier/repository yang sudah digunakan aplikasi.

## 2. Project yang diuji

| Item | Keterangan |
|---|---|
| Nama aplikasi | Notes App |
| Package | `notes_app` |
| Framework | Flutter 3.44.5 / Dart 3.12.2 |
| State management | Riverpod 2.6.1 |
| Database | SQLite (`sqflite`) |
| Fitur AI | Google Gemini API, secure storage, offline fallback |
| Perangkat integration test | Android Emulator `emulator-5554` (Android 17 / API 37) |

## 3. Fitur yang diuji

- Validasi judul catatan (`isValidNoteTitle`).
- Kontrak `NotesRepository` melalui fake repository.
- `NotesNotifier`: memuat data, loading, error, tambah, hapus, dan reload.
- `NotesScreen`: tampilan awal, data kosong, loading, error, daftar catatan, input tidak valid, tambah catatan, pencarian, dan hapus via swipe.
- Fitur lama yang tetap diuji: `filterNotes`, `EmptyStateWidget`, `AiService` (sanitasi privasi, API key, error HTTP, fallback), dan `ChatScreen`.
- Alur utama aplikasi secara end-to-end: tambah, cari, dan hapus catatan.

## 4. Skenario pengujian

### 4.1 Unit testing

| File | Jumlah | Skenario |
|---|---:|---|
| `test/note_title_validator_test.dart` | 3 | Judul berisi teks diterima; spasi di awal/akhir diterima; teks kosong/spasi/newline ditolak |
| `test/notes_notifier_test.dart` | 5 | Memuat data repository; error menjadi `AsyncError`; state `AsyncLoading`; `addNote` men-trim judul/body; `deleteNote` menghapus dan reload |
| `test/search_filter_test.dart` | 7 | Query kosong, spasi, case-insensitive, tidak cocok, partial match, hanya judul, satu karakter |
| `test/ai_service_test.dart` | 16 | Sanitasi NIK/telepon/email, secure storage, parsing respons, status 400/401/429/500, timeout, offline fallback |

### 4.2 Widget testing

| File | Jumlah | Skenario |
|---|---:|---|
| `test/widget/notes_screen_test.dart` | 8 | Tampilan awal; loading; daftar catatan; error; input judul tidak valid; tambah catatan lewat FAB + bottom sheet; filter pencarian; hapus via swipe |
| `test/widget/empty_state_widget_test.dart` | 5 | Empty state tanpa catatan dan saat pencarian tidak menemukan hasil |
| `test/widget/chat_screen_test.dart` | 4 | AppBar, pesan sambutan, quick prompts; modal API key; bersihkan obrolan; dialog fallback |

### 4.3 Integration testing

| File | Jumlah | Skenario |
|---|---:|---|
| `integration_test/app_test.dart` | 1 | Buka aplikasi; tambah catatan unik; verifikasi catatan tampil; cari catatan; verifikasi hasil filter; hapus catatan; verifikasi catatan hilang |

## 5. Hasil pengujian

### 5.1 Hasil unit testing

```bash
$ flutter test
00:02 +48: All tests passed!
```

Dari 48 test yang lulus, **31 merupakan unit test** (termasuk pengujian repository/async dan validator) dan **17 merupakan widget test**.

### 5.2 Hasil widget testing

Seluruh 17 widget test lulus, termasuk 8 widget test baru pada `notes_screen_test.dart`. Tidak ada test yang gagal atau dilewati.

### 5.3 Hasil integration testing

```bash
$ flutter test integration_test/app_test.dart -d emulator-5554
00:00 +0: pengguna dapat menambah, mencari, dan menghapus catatan
00:10 +1: (tearDownAll)
00:11 +1: All tests passed!
```

### 5.4 Hasil `flutter analyze`

```bash
$ flutter analyze
Analyzing 10-week-10-ai-feature-integration...
No issues found! (ran in 5.3s)
```

### 5.5 Hasil coverage

Perintah:

```bash
$ flutter test --coverage
00:05 +48: All tests passed!
```

Ringkasan coverage: **78,5% (694/884 baris)**. File `lcov.info` disalin ke `12-week-12-testing-quality-assurance/coverage/lcov.info`.

| File | Coverage |
|---|---:|
| `lib/features/notes/domain/note.dart` | 66,7% (8/12) |
| `lib/features/notes/domain/search_notes_use_case.dart` | 100% (5/5) |
| `lib/features/notes/domain/note_title_validator.dart` | 100% (2/2) |
| `lib/ai/ai_service.dart` | 86,7% (72/83) |
| `lib/ai/ai_provider.dart` | 66,7% (46/69) |
| `lib/features/chat_screen.dart` | 72,2% (208/288) |
| `lib/features/notes/presentation/notes_provider.dart` | 95,8% (23/24) |
| `lib/features/notes/presentation/notes_screen.dart` | 90,7% (117/129) |
| `lib/features/notes/presentation/widgets/add_note_sheet.dart` | 97,3% (73/75) |
| `lib/features/notes/presentation/widgets/note_card.dart` | 86,7% (72/83) |
| `lib/features/notes/presentation/widgets/search_bar_widget.dart` | 87,5% (28/32) |
| `lib/features/notes/presentation/widgets/empty_state_widget.dart` | 100% (40/40) |
| `lib/features/notes/data/app_database.dart` | 0% (0/16) |
| `lib/features/notes/data/note_dto.dart` | 0% (0/13) |
| `lib/features/notes/data/sqlite_notes_repository.dart` | 0% (0/13) |

## 6. File yang dibuat dan diubah

### Project Week 10

Dibuat:

- `lib/features/notes/domain/note_title_validator.dart`
- `test/note_title_validator_test.dart`
- `test/notes_notifier_test.dart`
- `test/fakes/fake_notes_repository.dart`
- `test/widget/notes_screen_test.dart`
- `integration_test/app_test.dart`

Diubah:

- `lib/features/notes/presentation/widgets/add_note_sheet.dart` (memakai validator dan menambahkan Key)
- `lib/features/notes/presentation/notes_screen.dart` (Key pada FAB)
- `pubspec.yaml` (menambahkan `integration_test`)
- `README.md` (hasil pengujian Week 12)

Tidak ada fitur yang dihapus dan desain UI tidak diubah.

### Folder Week 12

- Di-scaffold dengan `flutter create --project-name week12_testing --org com.vanesa --platforms=android,ios .`
- `lib/main.dart` diubah menjadi halaman ringkasan hasil pengujian (bukan aplikasi baru; hanya penanda folder praktikum).
- `test/widget_test.dart` berisi smoke test halaman ringkasan tersebut (`flutter test` di folder ini: 1 lulus, `flutter analyze`: tidak ada masalah).
- `README.md` berisi laporan ini.
- `coverage/lcov.info` berisi hasil coverage aktual.
- `coverage/` juga menyimpan salinan output perintah pengujian.
- `screenshots/app_notes_week10.png` berisi tangkapan layar aplikasi Week 10 yang menjadi target pengujian.

## 7. Kendala yang ditemukan

1. **Aplikasi tidak memiliki fitur tugas.** Contoh `TaskRepository`, `TaskService`, dan `isValidTaskTitle` tidak dipaksakan. Implementasi disesuaikan menjadi `NotesRepository`, `NotesNotifier`, dan `isValidNoteTitle` agar menguji kode yang benar-benar dipakai aplikasi.
2. **Data layer SQLite memiliki coverage 0% pada unit test.** `sqflite` membutuhkan platform Android/iOS, sehingga tidak dapat dijalankan di Dart VM. Kekurangan ini ditutup oleh integration test yang benar-benar menulis, membaca, mencari, dan menghapus data di emulator.
3. **Race condition saat menghapus catatan pada integration test.** `deleteNote` menjalankan reload async setelah swipe. Test sempat selesai sebelum reload selesai dan memunculkan `Bad state: Future already completed` dari Riverpod. Solusinya, integration test menunggu proses async dengan `tester.runAsync` selama 2 detik sebelum verifikasi akhir.
4. **Pengujian AI tidak memanggil Gemini API secara langsung.** Pemanggilan live tidak dilakukan agar tidak bergantung pada jaringan, kuota, dan biaya. `AiService` diuji menggunakan mock HTTP dan mock secure storage yang sudah tersedia.
5. **Folder Week 12 sebelumnya bukan proyek Flutter.** Folder di-scaffold agar valid sebagai proyek Flutter, tetapi kode aplikasi dan test tetap satu sumber di project Week 10 untuk menghindari duplikasi.

## 8. Kesimpulan

Praktikum Week 12 berhasil diterapkan pada aplikasi Week 10 dengan menyesuaikan konsep pengujian terhadap fitur asli Notes App. Seluruh 48 unit/widget test dan 1 integration test lulus, `flutter analyze` tidak menemukan masalah, dan coverage mencapai 78,5%. Pengujian berhasil memverifikasi validasi input, kontrak repository, state loading/error/empty, interaksi tambah/cari/hapus catatan, serta alur utama aplikasi pada emulator Android.
