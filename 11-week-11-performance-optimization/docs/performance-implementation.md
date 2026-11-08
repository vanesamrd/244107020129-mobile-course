# Week 11 — Performance Implementation

**Status:** F-01, F-02, dan F-03 sudah diimplementasikan.
**Lingkup perubahan:** hanya folder `11-week-11-performance-optimization`.
**Project Week 10:** tidak diubah.

> Dokumen ini **tidak** memuat angka before-after profiling. Pengukuran ulang frame time/rebuild dilakukan terpisah oleh pemilik tugas melalui Flutter DevTools.

---

## 1. File yang diubah

| File | Jenis perubahan |
|---|---|
| `lib/features/notes/presentation/widgets/search_bar_widget.dart` | Debounce 250 ms, hapus `setState()` untuk pencarian, ikon clear tetap berfungsi, Timer dibatalkan saat dispose |
| `lib/features/notes/presentation/notes_screen.dart` | Memecah layar menjadi `_NotesHeader`, `_AiBanner`, `_SearchResultChip`, dan `_NotesList`; `NotesScreen` tidak lagi me-watch seluruh state |
| `lib/features/notes/presentation/notes_provider.dart` | Tambah/hapus catatan memakai update state lokal; tidak ada `fetchAll()` ulang; rollback jika database gagal |
| `lib/features/notes/presentation/widgets/note_card.dart` | `_DeleteBackground` dijadikan widget `const` |
| `lib/features/chat_screen.dart` | `select` dan pemecahan subwidget untuk status AppBar, daftar pesan, quick prompts, dan input bar |
| `test/search_bar_debounce_test.dart` | Tes baru: debounce, ikon clear, clear dari luar search bar |
| `test/notes_provider_test.dart` | Tes baru: update lokal tambah/hapus dan rollback saat database gagal |
| `test/notes_screen_search_test.dart` | Tes integrasi baru: filter daftar dan clear pada `NotesScreen` |
| `docs/performance-implementation.md` | Dokumen ini |

Tidak ada perubahan pada:

- `pubspec.yaml` / dependency;
- skema database atau `note_dto.dart`;
- desain/tata letak UI;
- source code Week 10.

---

## 2. F-01 — Optimasi pencarian catatan

### Masalah sebelum optimasi

`NoteSearchBar` mengubah `searchQueryProvider` dan memanggil `setState()` pada setiap ketikan:

```dart
onChanged: (value) {
  ref.read(searchQueryProvider.notifier).state = value;
  setState(() {});
},
```

`NotesScreen` me-watch query dan hasil filter, sehingga satu karakter dapat membangun ulang header, banner AI, chip hasil, dan daftar. Filter `O(n)` juga langsung dijalankan ke seluruh catatan pada setiap ketikan.

### Perubahan yang diterapkan

1. **Debounce 250 ms** menggunakan `Timer`:
   - `onChanged` hanya menyimpan timer baru;
   - provider diperbarui setelah pengguna berhenti mengetik 250 ms;
   - timer lama selalu dibatalkan sebelum timer baru dibuat.
2. **Menghapus `setState()` untuk pencarian.**
   - Ikon clear memakai `ValueNotifier<bool>` + `ValueListenableBuilder`;
   - hanya bagian ikon/TextField yang perlu yang dibangun ulang saat status kosong/terisi berubah.
3. **Ikon clear tetap berfungsi.**
   - `_clearSearch()` membatalkan timer, mengosongkan controller, dan langsung mengosongkan query;
   - provider mendengarkan perubahan dari luar (misalnya tombol “Hapus Pencarian” di empty state) dan menyinkronkan controller.
4. **Pencegahan memory leak.**
   - `_debounce?.cancel()` dipanggil di `dispose()`;
   - callback timer memeriksa `mounted` sebelum memakai `ref`;
   - listener controller dilepas dan `ValueNotifier` di-dispose.

### Mengapa mengurangi pekerjaan tidak perlu?

- Filter tidak lagi dijalankan untuk setiap karakter, tetapi maksimal sekali setelah jeda mengetik.
- Perubahan query hanya membangun ulang subwidget yang membutuhkan query, bukan seluruh `CustomScrollView`.
- `setState()` tidak lagi menandai seluruh search bar setiap karakter hanya untuk mengganti ikon clear.

### Cara menguji

1. Jalankan aplikasi, ketik cepat di kolom pencarian.
2. Pastikan daftar baru terfilter setelah berhenti mengetik ±250 ms, bukan pada setiap karakter.
3. Tekan ikon clear:
   - teks dan query harus kosong;
   - daftar kembali menampilkan semua catatan.
4. Tekan “Hapus Pencarian” pada empty state:
   - teks di kolom pencarian ikut kosong.
5. Tes otomatis:
   ```bash
   flutter test test/search_bar_debounce_test.dart
   flutter test test/notes_screen_search_test.dart
   ```

Catatan: debounce sengaja menambah jeda kecil sebelum hasil filter berubah. Ini trade-off yang disepakati untuk mengurangi jumlah pekerjaan.

---

## 3. F-02 — Optimasi Riverpod

### Masalah sebelum optimasi

`NotesScreen` me-watch tiga state sekaligus:

```dart
final filteredAsync = ref.watch(filteredNotesProvider);
final allAsync = ref.watch(notesProvider);
final query = ref.watch(searchQueryProvider);
```

Perubahan query atau daftar catatan membangun ulang seluruh layar. `ChatScreen` juga me-watch seluruh `ChatState`, sehingga perubahan `messages`, `isLoading`, atau `hasApiKey` membangun ulang seluruh body chat.

### Perubahan yang diterapkan

1. **`NotesScreen` hanya menyusun struktur.** State dipindahkan ke subwidget:
   - `_NotesHeader`: hanya me-watch jumlah catatan dengan `notesProvider.select(...)`;
   - `_AiBanner`: hanya me-watch status “sedang mencari” dengan `searchQueryProvider.select(...)`;
   - `_SearchResultChip`: hanya menangani query dan hasil filter untuk chip;
   - `_NotesList`: hanya menangani daftar hasil filter dan empty state.
2. **`select` dipakai untuk data sempit**, misalnya jumlah catatan, status search, `messages`, `isLoading`, dan `hasApiKey`.
3. **`const` digunakan pada widget yang memungkinkan**, termasuk `_NotesHeader`, `_AiBanner`, `_SearchResultChip`, `_NotesList`, `CustomScrollView` di `NotesScreen`, dan `_DeleteBackground`.
4. **`ChatScreen` dipecah dengan aman**:
   - `_ChatStatus` hanya rebuild saat status API key berubah;
   - `_ChatMessages` hanya rebuild saat `messages`/`isLoading` berubah;
   - `_QuickPromptsBar` hanya rebuild saat `isLoading` berubah;
   - `_ChatInputBar` hanya rebuild saat `isLoading` berubah.
5. Perilaku fitur tidak diubah: teks, tombol, status loading, pengiriman pesan, copy, simpan catatan, dan dialog API key tetap sama.

### Mengapa mengurangi pekerjaan tidak perlu?

Dengan `select`, Riverpod hanya memberi notifikasi jika bagian yang dipilih benar-benar berubah. Dengan pemecahan widget, rebuild terbatas pada subtree yang datanya berubah. Header, search bar, banner, dan input chat tidak ikut dibangun ulang ketika bagian lain berubah.

### Cara menguji

1. Buka DevTools → Widget Inspector → **Track Widget Rebuilds**.
2. Di layar catatan:
   - mengetik pencarian seharusnya tidak membangun ulang `_NotesHeader`;
   - menambah catatan seharusnya tidak membangun ulang search bar dan banner.
3. Di layar AI:
   - mengirim pesan seharusnya membangun ulang daftar pesan dan input yang membutuhkan `isLoading`, bukan seluruh `ChatScreen`.
4. Pastikan semua interaksi lama tetap berjalan: kirim pesan, quick prompt, copy, simpan catatan, buka pengaturan API key, bersihkan obrolan.
5. Tes otomatis:
   ```bash
   flutter test test/widget/chat_screen_test.dart
   flutter test test/notes_screen_search_test.dart
   ```

---

## 4. F-03 — Optimasi tambah dan hapus catatan

### Masalah sebelum optimasi

Setiap tambah/hapus memanggil `reload()`:

```dart
await ref.read(notesRepositoryProvider).save(note);
await reload();
```

`reload()` mengubah state menjadi `AsyncLoading`, lalu `fetchAll()` membaca ulang seluruh tabel. Akibatnya daftar sempat berubah menjadi spinner dan semua baris dipetakan ulang.

### Perubahan yang diterapkan

1. **Tambah catatan memakai hasil `save()`:**
   - `savedNote` yang sudah memiliki `id` langsung dimasukkan ke state;
   - catatan baru diletakkan di awal list karena query SQLite memakai urutan `created_at DESC`;
   - tidak ada `fetchAll()` tambahan.
2. **Hapus catatan memakai filter berdasarkan `id`:**
   - item langsung dihapus dari state lokal;
   - database dihapus setelahnya;
   - tidak ada `fetchAll()` tambahan.
3. **`AsyncData` dipertahankan saat mutasi**, sehingga daftar tidak berubah menjadi loading.
4. **Rollback saat database gagal:**
   - state sebelumnya disimpan sebelum operasi;
   - jika `save()` atau `delete()` melempar error, state dikembalikan ke kondisi semula;
   - error tetap dilempar kembali agar pemanggil dapat menanganinya.
5. `reload()` tetap tersedia untuk kebutuhan eksplisit (misalnya refresh penuh), tetapi tidak lagi dipanggil oleh `addNote()` atau `deleteNote()`.

### Mengapa mengurangi pekerjaan tidak perlu?

- Satu mutasi tidak lagi diikuti `SELECT` seluruh tabel.
- Tidak ada mapping ulang semua baris.
- Tidak ada transisi `AsyncData → AsyncLoading → AsyncData` yang memicu rebuild/spinner.
- Update lokal hanya mengubah satu list di memori.

### Cara menguji

1. Tambah catatan:
   - daftar tidak berubah menjadi spinner;
   - catatan baru muncul di atas;
   - tutup dan buka aplikasi, catatan tetap ada.
2. Hapus catatan dengan swipe:
   - item langsung hilang;
   - buka ulang aplikasi, item tetap tidak ada.
3. Uji kegagalan database (lewat fake repository pada tes):
   - saat `save` gagal, state lama tetap utuh;
   - saat `delete` gagal, item yang sudah dihapus lokal muncul kembali.
4. Tes otomatis:
   ```bash
   flutter test test/notes_provider_test.dart
   ```

Tes memastikan `fetchAllCalls` tidak bertambah setelah tambah/hapus.

---

## 5. Hasil pengujian setelah implementasi

Perintah yang dijalankan di folder Week 11:

```bash
flutter analyze
flutter test
flutter build macos --debug
```

Hasil:

- `flutter analyze` → **No issues found**
- `flutter test` → **40 tests passed**
- `flutter build macos --debug` → **berhasil** membuat `notes_app.app`
- `flutter pub get` tidak diperlukan karena tidak ada dependency baru/perubahan `pubspec.yaml`

Rincian tes baru:

- `test/search_bar_debounce_test.dart` — 3 tes;
- `test/notes_provider_test.dart` — 4 tes;
- `test/notes_screen_search_test.dart` — 1 tes.

---

## 6. Yang belum diukur di dokumen ini

Sesuai instruksi, dokumen ini tidak mencantumkan angka before-after. Untuk memverifikasi dampak performa, lakukan pengukuran terpisah:

1. `flutter run --profile`
2. DevTools Performance
3. Rekam skenario:
   - mengetik 20–30 karakter pencarian;
   - tambah catatan;
   - hapus catatan;
   - kirim pesan AI;
   - scroll daftar dengan data banyak.
4. Bandingkan frame time, jumlah jank, jumlah query, dan jumlah rebuild sebelum vs sesudah.
