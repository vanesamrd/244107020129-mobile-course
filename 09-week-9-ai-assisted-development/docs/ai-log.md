# AI Development Log – Week 9

## Praktikum 1 – Prompt Engineering

### Prompt Utama (5 Slot)

```
Peran    : senior Flutter developer
Konteks  : feature-first (presentation→domain←data), Riverpod, SQLite+Dio, Flutter 3.44
Tugas    : tambah fitur search judul notes + empty state
Batas    : jangan ubah arsitektur; domain murni (tidak ada import Flutter/Dio/SQLite);
           maks 80 baris per file; gunakan filterNotes(List<Note>, String) sebagai use case
Output   : kode + minimal 2 test case (sukses & gagal) + cara uji manual
```

**Konteks yang disertakan:**
```
Struktur folder:
lib/features/notes/
  domain/  note.dart  notes_repository.dart  search_notes_use_case.dart
  data/    sqlite_notes_repository.dart  note_dto.dart  app_database.dart
  presentation/ notes_provider.dart  notes_screen.dart  widgets/

Kontrak repository (domain/notes_repository.dart):
abstract interface class NotesRepository {
  Future<List<Note>> fetchAll();
  Future<Note> save(Note note);
  Future<void> delete(int id);
}

Versi package (pubspec.yaml):
  flutter_riverpod: ^2.6.1
  sqflite: ^2.4.1
  dio: ^5.8.0+1
```

**Yang TIDAK boleh diubah:** layer domain tidak boleh mengimport sqflite, dio, atau flutter/material.

---

## Praktikum 2 – Generate & Verifikasi Search

### Prompt Buruk vs Baik

| | Prompt |
|---|---|
| **Buruk** | "buatkan search notes yang keren" |
| **Baik** | "Tambah search judul notes. Arsitektur: presentation→domain←data. Jangan panggil SQLite dari widget. Sertakan empty state + 1 widget test." |

### Output Awal AI (ringkasan)

AI menghasilkan `filterNotes` dalam use case domain — **diterima** karena:
- Fungsi murni, tidak ada import framework
- Dapat diuji tanpa mock apapun
- Terbukti benar lewat unit test

AI menghasilkan `searchQuery` sebagai field dalam `NotesNotifier` — **ditolak** karena:
- Query search bukan state dari notifier notes, melainkan state UI tersendiri
- Melanggar prinsip single responsibility
- **Bukti:** `grep -r "searchQuery" lib/features/notes/presentation/notes_provider.dart` → 0 hasil setelah refactor; search query dipindah ke `StateProvider<String>` terpisah

### Verifikasi 6 Langkah

- [x] **1. Baca tiap baris** – semua baris domain dipahami, tidak ada yang membingungkan
- [x] **2. Cek import domain/** – `grep -r "import.*sqflite\|import.*dio\|import.*flutter/material" lib/features/notes/domain/` → 0 hasil ✅
- [x] **3. Cek API** – `filterNotes`, `StateProvider`, `AsyncNotifierProvider` semua valid di pub.dev + autocomplete
- [x] **4. flutter analyze** – 0 warning setelah perbaikan
- [x] **5. Test sukses & gagal** – lihat `test/search_filter_test.dart`
- [x] **6. Uji manual** – query kosong ✅, cocok ✅, tidak cocok (empty state) ✅

### Bukti Bug/Halusinasi yang Ditemukan

**Halusinasi:** AI awalnya menyarankan `db.query(table, where: "title LIKE '%?%'", whereArgs: [query])` untuk filter di SQLite layer.

**Masalah:** Parameter `?` dalam SQLite tidak bekerja di dalam string literal `'%?%'` — binding hanya berlaku untuk nilai lengkap, bukan substring LIKE. Hasilnya selalu mengembalikan 0 baris.

**Bukti:**
```bash
# Test merah yang membuktikan bug:
# filterNotes dengan implementasi DB-based selalu kembalikan kosong
# Diselesaikan dengan memindahkan filter ke domain (pure Dart), bukan di SQL
grep -rn "LIKE" lib/  # → 0 hasil → konfirmasi filter dipindah ke domain
```

**Solusi:** Filter dilakukan di domain use case (`filterNotes`) atas data yang sudah di-fetch, bukan di query SQL. Ini lebih testable dan tidak ada risiko SQL injection.

---

## Praktikum 3 – Debug & Refactor

### Akar Masalah: Filter di Layer Salah

**Sebelum refactor:**
```dart
// ❌ Widget langsung filter — melanggar arsitektur
final filtered = notes.where((n) => n.title.contains(query)).toList();
```

**Setelah refactor:**
```dart
// ✅ Widget hanya consume provider; logic ada di domain
final filteredAsync = ref.watch(filteredNotesProvider);
```

**Langkah debug:**
1. Reproduksi: query 'BELANJA' tidak mengembalikan hasil (case-sensitive bug)
2. Isolasi: pindah filter ke `search_notes_use_case.dart`
3. Test merah: `expect(filterNotes(notes, 'BELANJA'), hasLength(2))` → FAIL
4. Perbaiki: `n.title.toLowerCase().contains(trimmed)` → test PASS
5. Catat: akar masalah = case sensitivity tidak ditangani

---

## AI Challenge – Review Kode

### Prompt Review

```
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation→domain←data), Riverpod, SQLite+Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### 3 Temuan AI

| # | Temuan | Level | Keputusan |
|---|--------|-------|-----------|
| 1 | Filter di widget langsung (sebelum refactor) | **BLOCKER** | ✅ Diterima + diperbaiki — dipindah ke use case domain |
| 2 | Tidak ada `trimmed.isEmpty` guard → query spasi mengembalikan 0 hasil | **BLOCKER** | ✅ Diterima + diperbaiki — tambah `trim()` + return semua jika kosong |
| 3 | Saran tambahkan debounce di search bar (300ms) agar performa lebih baik | **SARAN** | ❌ Ditolak — kompleksitas tidak perlu untuk data lokal SQLite; SQLite query di-in-memory setelah fetch, tidak ada network latency. Cukup untuk scope codelab ini. |

### Bukti Temuan #1 Valid (grep)

```bash
grep -n "where.*title.*contains" lib/features/notes/presentation/
# → 0 hasil setelah refactor ke use case
grep -n "filterNotes" lib/features/notes/domain/search_notes_use_case.dart
# → line 10: List<Note> filterNotes(...)
```

### Alasan Tolak Temuan #3

Data disimpan lokal di SQLite, sudah di-fetch ke memori Dart. `filterNotes` hanya iterasi list in-memory — O(n) sangat cepat untuk ratusan notes. Debounce menambah kompleksitas state (Timer, dispose) tanpa manfaat nyata. Keputusan: tolak, dokumentasikan sebagai future enhancement jika data >10.000 notes.

---

## Refleksi

**Halusinasi yang ditemukan:**
AI menyarankan LIKE query dengan `'%?%'` di SQLite yang tidak bekerja karena binding `?` tidak ditempatkan di dalam string literal. Dibuktikan lewat test yang mengembalikan 0 baris dan kemudian diperbaiki dengan memindahkan filter ke domain pure Dart.

**Prompt paling membantu:**
Prompt dengan 5 slot (Peran + Konteks + Tugas + Batas + Output) dengan kontrak repository yang disertakan. Ini membuat AI langsung menghasilkan kode yang sesuai arsitektur.

**Refactor yang dilakukan:**
Memindahkan `searchQuery` dari field `NotesNotifier` ke `StateProvider<String>` terpisah. Ini memisahkan "state query UI" dari "state list notes", sehingga masing-masing bisa di-watch secara independen.

**Keputusan terima/tolak paling sulit:**
Keputusan menolak saran debounce — AI memberikan alasan yang masuk akal (UX dan performa), namun setelah mempertimbangkan scope proyek dan data lokal in-memory, ditolak karena kompleksitas tidak sepadan.
