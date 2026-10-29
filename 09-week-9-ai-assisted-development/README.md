# Notes App – Week 9: AI-Assisted Development

Aplikasi catatan Flutter dengan fitur **search/filter judul** dan **empty state**, dibangun menggunakan arsitektur feature-first dengan Riverpod, SQLite, dan Dio.

## Fitur

- 📝 Tambah, hapus, dan lihat catatan
- 🔍 **Search catatan berdasarkan judul** (case-insensitive, real-time)
- 📭 **Empty state** yang informatif (beda pesan untuk "belum ada catatan" vs "tidak ada hasil pencarian")
- 🏗️ Arsitektur bersih: `presentation → domain ← data`

## Stack

| Layer | Package |
|---|---|
| State Management | `flutter_riverpod ^2.6.1` |
| Database Lokal | `sqflite ^2.4.1` |
| HTTP Client | `dio ^5.8.0+1` |
| Testing | `flutter_test`, `mocktail ^1.0.4` |

## Struktur Folder

```
lib/
└── features/
    └── notes/
        ├── domain/                         # Pure Dart – no framework imports
        │   ├── note.dart                   # Entity
        │   ├── notes_repository.dart       # Interface / kontrak
        │   └── search_notes_use_case.dart  # filterNotes() – logika filter
        ├── data/                           # SQLite implementation
        │   ├── app_database.dart
        │   ├── note_dto.dart
        │   └── sqlite_notes_repository.dart
        └── presentation/                   # Flutter UI + Riverpod
            ├── notes_provider.dart
            ├── notes_screen.dart
            └── widgets/
                ├── search_bar_widget.dart
                ├── note_card.dart
                └── empty_state_widget.dart
test/
├── search_filter_test.dart          # Unit tests untuk filterNotes
└── widget/
    └── empty_state_widget_test.dart # Widget tests untuk empty state
docs/
└── ai-log.md                        # Prompt, output AI, tabel terima/tolak, refleksi
```

## Cara Menjalankan

```bash
# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run

# Analyze
flutter analyze

# Format
dart format --set-exit-if-changed .

# Test
flutter test
```

## Prompt Inti (5 Slot)

```
Peran    : senior Flutter developer
Konteks  : feature-first (presentation→domain←data), Riverpod, SQLite+Dio, Flutter 3.44
Tugas    : tambah fitur search judul notes + empty state
Batas    : domain murni (tidak ada import Flutter/Dio/SQLite); maks 80 baris per file
Output   : kode + minimal 2 test case (sukses & gagal) + cara uji manual
```

## Hasil Mesin Hijau

```
flutter analyze  → 0 issues
flutter test     → All tests passed ✅
```

## Tabel Terima / Tolak Saran AI

| Temuan AI | Level | Keputusan | Alasan |
|---|---|---|---|
| Filter di widget langsung melanggar arsitektur | BLOCKER | ✅ Terima + perbaiki | Dipindah ke `filterNotes` use case di domain |
| Query spasi tidak di-trim → hasil salah | BLOCKER | ✅ Terima + perbaiki | Tambah `trim()` + guard empty check |
| Tambah debounce 300ms di search bar | SARAN | ❌ Tolak | Data in-memory SQLite, O(n) sangat cepat, kompleksitas tidak perlu |

## Bukti Verifikasi

```bash
# Domain bebas dari import framework:
grep -r "import.*sqflite\|import.*dio\|import.*flutter/material" lib/features/notes/domain/
# → 0 hasil ✅

# Filter ada di use case, bukan widget:
grep -n "filterNotes" lib/features/notes/domain/search_notes_use_case.dart
# → line 10: List<Note> filterNotes(List<Note> notes, String query)
```

## Screenshots

> Lihat folder `screenshots/` untuk tampilan UI (query kosong, hasil cocok, empty state).

## Refleksi Singkat

- **Halusinasi ditemukan:** AI menyarankan `LIKE '%?%'` di SQLite — tidak bekerja; dipindah ke filter domain pure Dart
- **Prompt terbaik:** 5-slot prompt dengan kontrak repository disertakan
- **Refactor utama:** `searchQuery` dipisah dari `NotesNotifier` ke `StateProvider` tersendiri
- **Keputusan sulit:** Menolak debounce — argumen AI valid tapi scope tidak membutuhkannya
