# Week 11 — Performance Findings

**Status:** analisis awal. F-01, F-02, dan F-03 sudah diimplementasikan; rincian perubahan ada di `docs/performance-implementation.md`.
**Lingkup:** `lib/` Week 11 (hasil salinan Week 10).
**Tujuan:** menemukan kandidat optimasi performa sebelum implementasi.

---

## 1. Metode dan batasan

Analisis dilakukan dengan membaca alur kode dari UI → Riverpod → repository → SQLite.

> **Catatan penting soal profiling**
>
> Di dalam repository Week 11 tidak ditemukan file export data mentah (JSON/CSV). Enam screenshot PNG profiling tersedia di `screenshots/`, tetapi screenshot tersebut tidak memuat total frame/janky frame dan tidak berlabel `before`/`after`. Ringkasan angka baseline diberikan secara terpisah dan dicatat di `docs/performance-report.md`; file mentahnya tetap tidak tersedia di repo ini.
>
> Karena itu dokumen ini **tidak mengarang angka FPS, waktu build, atau durasi query**. Temuan di bawah dibuktikan dari jalur kode yang jelas. Besarnya dampak runtime tetap harus diukur ulang dengan DevTools sebelum dan sesudah optimasi.

Kategori bukti:

- **Terbukti dari kode** — jalur eksekusi dan pekerjaan tambahan terlihat langsung di source.
- **Perlu diuji** — baru dugaan atau bergantung pada jumlah data/device.

---

## 2. Ringkasan prioritas

| ID | Prioritas | Temuan | Status bukti |
|---|---|---|---|
| F-01 | P1 | Setiap ketikan di kolom pencarian membangun ulang seluruh `NotesScreen` dan menjalankan filter ke semua catatan | Terbukti dari kode; dampak FPS perlu diukur |
| F-02 | P2 | Riverpod dipakai untuk me-watch state terlalu lebar, sehingga widget yang tidak berubah ikut rebuild | Terbukti dari kode |
| F-03 | P3 | Tambah/hapus catatan memanggil `reload()` yang membaca ulang seluruh tabel dan sempat menampilkan loading | Terbukti dari kode |
| F-04 | P4 | `fetchAll()` mengambil seluruh baris tanpa pagination/limit | Terbukti dari kode; dampak tergantung jumlah data |
| F-05 | Perlu diuji | Biaya rebuild/raster `NoteCard` dan animasi daftar saat scroll | Belum cukup bukti |

---

## 3. F-01 — Rebuild berlebihan saat mencari catatan

### Gejala yang terlihat dari kode

Setiap karakter yang diketik di `NoteSearchBar` melakukan dua hal sekaligus:

1. Mengubah `searchQueryProvider`.
2. Memanggil `setState()` pada widget search bar.

```dart
// lib/features/notes/presentation/widgets/search_bar_widget.dart:66-69
onChanged: (value) {
  ref.read(searchQueryProvider.notifier).state = value;
  setState(() {});
},
```

`NotesScreen` sendiri me-watch tiga sumber sekaligus:

```dart
// lib/features/notes/presentation/notes_screen.dart:19-21
final filteredAsync = ref.watch(filteredNotesProvider);
final allAsync = ref.watch(notesProvider);
final query = ref.watch(searchQueryProvider);
```

Akibatnya, satu ketikan memicu:

- rebuild `NoteSearchBar` karena `setState()`;
- rebuild `NotesScreen` karena `searchQueryProvider` berubah;
- perhitungan ulang `filteredNotesProvider` karena ia juga me-watch query;
- rebuild `SliverAppBar`, banner AI, chip hasil pencarian, dan `SliverList`;
- rebuild semua `NoteCard` yang sedang terlihat (bukan seluruh daftar, karena `SliverList` hanya membangun item yang terlihat).

Filter dijalankan ke seluruh catatan setiap ketikan:

```dart
// lib/features/notes/presentation/notes_provider.dart:72-76
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  return notesAsync.whenData((notes) => filterNotes(notes, query));
});
```

```dart
// lib/features/notes/domain/search_notes_use_case.dart:9-15
List<Note> filterNotes(List<Note> notes, String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return List.unmodifiable(notes);
  return notes
      .where((n) => n.title.toLowerCase().contains(trimmed))
      .toList(growable: false);
}
```

### Penyebab

- Tidak ada debounce: setiap karakter langsung menjadi state global dan langsung memicu filter.
- Cakupan rebuild terlalu besar: `NotesScreen` adalah satu `ConsumerWidget` besar yang me-watch query, daftar hasil filter, dan daftar lengkap.
- `setState()` dipakai hanya untuk mengganti ikon clear di dalam `TextField`, tetapi efeknya ikut membangun ulang seluruh isi search bar.
- Query disimpan di dua tempat (controller lokal dan provider), sehingga UI harus disinkronkan dengan dua mekanisme.

### Dampak

- Untuk catatan sedikit (misalnya 10–50), biaya ini mungkin belum terasa.
- Untuk catatan ratusan/ribuan, filter `O(n)` dan rebuild subtree besar dapat menambah kerja di UI thread setiap ketikan. Apakah sampai menyebabkan jank **belum diukur**.

### Solusi yang disarankan (belum diterapkan)

1. **Debounce query** sekitar 250–300 ms. Update `searchQueryProvider` hanya setelah pengguna berhenti mengetik; batalkan timer di `dispose()`.
2. **Hilangkan `setState()` untuk ikon clear.** Gunakan `ValueListenableBuilder<TextEditingValue>` pada controller agar hanya `suffixIcon` yang rebuild, bukan seluruh search bar.
3. **Pecah `NotesScreen` menjadi widget kecil**:
   - header hanya me-watch jumlah catatan;
   - daftar hanya me-watch hasil filter;
   - banner/chip hanya me-watch query bila memang perlu.
4. **Kurangi watch langsung ke `searchQueryProvider`** dari layar utama. Pindahkan bagian yang bergantung query ke `Consumer` kecil.
5. **Jadikan `NoteSearchBar` const** di parent agar rebuild parent tidak otomatis membangun ulang search bar.
6. Jika data nanti sangat besar, pertimbangkan pencarian di SQLite (`WHERE title LIKE ?`) dengan indeks, bukan memfilter seluruh list di memori.

### Cara memverifikasi

- Jalankan `flutter run --profile`.
- Buka DevTools Performance, rekam saat mengetik 20–30 karakter di kolom pencarian.
- Bandingkan jumlah frame yang melewati 16 ms (jank) dan `build` count `NotesScreen`/`NoteCard` sebelum vs sesudah debounce dan pemecahan widget.

---

## 4. F-02 — Riverpod me-watch state terlalu lebar

### Bukti pada layar catatan

```dart
// lib/features/notes/presentation/notes_screen.dart:19-21
final filteredAsync = ref.watch(filteredNotesProvider);
final allAsync = ref.watch(notesProvider);
final query = ref.watch(searchQueryProvider);
```

`NotesScreen` me-watch `notesProvider` **dan** `filteredNotesProvider`. Padahal `filteredNotesProvider` sudah me-watch `notesProvider` di dalamnya. `notesProvider` juga hanya dipakai untuk menghitung `totalNotes` di header:

```dart
// lib/features/notes/presentation/notes_screen.dart:24
final totalNotes = allAsync.valueOrNull?.length ?? 0;
```

Artinya, perubahan besar pada daftar catatan menandai seluruh layar (header, search bar, banner, chip, dan daftar) untuk rebuild, padahal header hanya butuh satu angka.

### Bukti pada layar AI

```dart
// lib/features/chat_screen.dart:319
final chatState = ref.watch(chatProvider);
```

`ChatScreen` me-watch seluruh `ChatState`. Setiap perubahan `messages`, `isLoading`, `errorMessage`, atau `hasApiKey` membangun ulang seluruh body: `ListView.builder`, quick prompt chips, dan input bar.

```dart
// lib/ai/ai_provider.dart:117-121 dan 133-136
state = state.copyWith(
  messages: [...state.messages, userMsg],
  isLoading: true,
  errorMessage: null,
);
// ...
state = state.copyWith(
  messages: [...state.messages, aiMsg],
  isLoading: false,
);
```

Saat mengirim satu pesan, state berubah minimal dua kali (pesan user + loading, lalu respons AI + loading selesai). Keduanya memicu rebuild `ChatScreen`.

### Penyebab

- `ref.watch` dipasang pada objek state besar (`AsyncValue<List<Note>>`, `ChatState`) alih-alih bagian yang dibutuhkan.
- Belum ada `select` atau pemisahan `Consumer` per subtree.
- Widget besar menggabungkan banyak tanggung jawab dalam satu `build()`.

### Dampak

- Rebuild terjadi pada widget yang tidak berubah. Flutter tetap perlu menjalankan `build()` dan diff elemen, walaupun hasil visualnya sama.
- Dampak paling jelas pada layar dengan banyak subtree, seperti `NotesScreen` dan `ChatScreen`.
- Ini belum tentu menyebabkan jank, tetapi jelas merupakan pekerjaan yang bisa dikurangi.

### Solusi yang disarankan (belum diterapkan)

1. Gunakan `select` untuk data yang sempit. Contoh untuk header:
   ```dart
   final totalNotes = ref.watch(
     notesProvider.select((value) => value.valueOrNull?.length ?? 0),
   );
   ```
2. Pecah layar menjadi `ConsumerWidget` kecil:
   - `_NotesHeader` → hanya jumlah catatan;
   - `_NotesList` → hanya `filteredNotesProvider`;
   - `_SearchSection` → hanya query;
   - `_AiBanner` → hanya status yang diperlukan.
3. Pada `ChatScreen`, pisahkan watch:
   - `ref.watch(chatProvider.select((s) => s.messages))` untuk daftar pesan;
   - `select((s) => s.isLoading)` untuk tombol/loading;
   - `select((s) => s.hasApiKey)` untuk status di AppBar.
4. Gunakan `const` pada widget yang tidak bergantung state.

### Cara memverifikasi

- Aktifkan **Track Widget Rebuilds** di DevTools.
- Rekam saat mengetik pencarian, menambah catatan, dan mengirim pesan AI.
- Hitung berapa kali `NotesScreen`, `ChatScreen`, `NoteCard`, dan input bar rebuild.
- Setelah pemecahan widget, subtree yang tidak berubah seharusnya tidak ikut rebuild.

---

## 5. F-03 — Reload seluruh daftar setelah tambah/hapus catatan

### Bukti

```dart
// lib/features/notes/presentation/notes_provider.dart:29-34
Future<void> reload() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(
    () => ref.read(notesRepositoryProvider).fetchAll(),
  );
}
```

`reload()` dipanggil setelah setiap tambah dan hapus:

```dart
// lib/features/notes/presentation/notes_provider.dart:36-55
Future<void> addNote({...}) async {
  // ...
  await ref.read(notesRepositoryProvider).save(note);
  await reload();
}

Future<void> deleteNote(int id) async {
  await ref.read(notesRepositoryProvider).delete(id);
  await reload();
}
```

`fetchAll()` membaca ulang seluruh tabel:

```dart
// lib/features/notes/data/sqlite_notes_repository.dart:18-22
Future<List<Note>> fetchAll() async {
  final db = await _db.database;
  final rows = await db.query(NoteDto.table, orderBy: 'created_at DESC');
  return rows.map(NoteDto.fromMap).toList(growable: false);
}
```

### Penyebab

- Hasil `save()` yang sebenarnya sudah mengembalikan `Note` dengan `id` baru malah dibuang.
- Setelah mutasi, aplikasi melakukan perjalanan tambahan: tulis ke SQLite → set `AsyncLoading` → baca semua baris → mapping ulang semua baris → ganti state.
- `AsyncLoading` membuat `filteredNotesProvider` juga mengembalikan loading, sehingga daftar diganti spinner dan muncul kembali.

### Dampak

- Muncul efek kedip/loading pada daftar setiap kali menambah atau menghapus satu catatan.
- Ada satu query `SELECT` penuh yang tidak perlu setelah setiap mutasi.
- Semua item yang terlihat dibangun ulang karena state berubah dari loading → data.
- Pada data besar, membaca dan memetakan ulang seluruh tabel menjadi makin mahal.

### Solusi yang disarankan (belum diterapkan)

1. **Tambah catatan secara lokal** menggunakan hasil `save()`:
   ```dart
   final saved = await repository.save(note);
   final current = state.valueOrNull ?? const <Note>[];
   state = AsyncData([saved, ...current]);
   ```
   `saved` sudah memiliki `id` dari SQLite dan waktu `createdAt` terbaru, jadi cocok diletakkan di atas (urutan `created_at DESC`).

2. **Hapus catatan secara lokal** tanpa membaca ulang:
   ```dart
   final current = state.valueOrNull;
   if (current != null) {
     state = AsyncData(
       current.where((n) => n.id != id).toList(growable: false),
     );
   }
   await repository.delete(id);
   ```
   Untuk keamanan, simpan state sebelumnya dan kembalikan bila `delete` gagal.

3. **Pertahankan `AsyncData`** selama mutasi agar daftar tidak berubah menjadi spinner.
4. Panggil `reload()` hanya untuk:
   - pemuatan awal;
   - pull-to-refresh;
   - pemulihan setelah error;
   - kebutuhan sinkronisasi eksternal.
5. Jika nanti ada banyak mutasi, pertimbangkan operasi batch atau antrean, bukan reload per item.

### Cara memverifikasi

- Ukur durasi dan jumlah query SQLite saat tambah/hapus (bisa dengan log sementara di repository).
- Rekam DevTools Performance saat menekan Simpan dan saat swipe-to-delete.
- Bandingkan jumlah frame, kemunculan spinner, dan rebuild daftar sebelum vs sesudah update lokal.
- Pastikan data tetap benar setelah aplikasi ditutup dan dibuka kembali (persistensi SQLite tidak berubah).

---

## 6. F-04 — `fetchAll()` tanpa pagination

### Bukti

`SqliteNotesRepository.fetchAll()` mengambil semua baris tanpa `limit`/`offset`:

```dart
// lib/features/notes/data/sqlite_notes_repository.dart:18-22
final rows = await db.query(NoteDto.table, orderBy: 'created_at DESC');
```

### Penilaian

Ini **terbukti dari kode**, tetapi apakah menjadi masalah tergantung jumlah catatan. Untuk aplikasi catatan pribadi dengan puluhan catatan, dampaknya kecil. Untuk ratusan/ribuan catatan, waktu query, alokasi list, dan rebuild akan meningkat.

### Solusi yang disarankan (belum diterapkan)

- Tambahkan pagination (`LIMIT`/`OFFSET` atau cursor berbasis `created_at`/`id`) bila jumlah catatan diprediksi besar.
- Untuk pencarian, pertimbangkan query SQL dengan filter, bukan memuat semua lalu memfilter di Dart.
- Ini sebaiknya dikerjakan setelah F-01–F-03, karena ketiganya memberi perbaikan tanpa mengubah model data.

---

## 7. Hal yang belum bisa disimpulkan (perlu diuji)

Hal-hal berikut **tidak** diklaim sebagai masalah terbukti:

1. **Jank saat scroll daftar.** `NoteCard` membangun `Container`, `BoxShadow`, `Dismissible`, dan `InkWell`. Perlu direkam dengan DevTools untuk melihat apakah raster/build-nya melewati budget frame.
2. **Biaya animasi `EmptyStateWidget`.** Animasi 500 ms hanya berjalan saat empty state tampil, jadi kemungkinan kecil menjadi masalah utama.
3. **Efek `SelectableText` di setiap bubble chat.** Bisa menambah biaya layout, tetapi belum diukur.
4. **Pengaruh ukuran data nyata.** Baseline perlu menyebut jumlah catatan yang dipakai. Tanpa angka itu, klaim “lambat” tidak bisa dibandingkan secara adil.

---

## 8. Rencana verifikasi sebelum optimasi

Sebelum mengubah kode, sebaiknya lengkapi baseline berikut:

| Skenario | Metrik yang dicatat |
|---|---|
| Mengetik 20–30 karakter di pencarian | frame time, jumlah jank, rebuild `NotesScreen`/`NoteCard` |
| Tambah 1 catatan | durasi operasi, jumlah query, munculnya spinner, rebuild daftar |
| Hapus 1 catatan | durasi operasi, jumlah query, rebuild daftar |
| Buka layar AI dan kirim 1 pesan | rebuild `ChatScreen`, frame time saat mengetik/scroll |
| Scroll daftar 100+ catatan | frame time, raster time |

Alat:

- `flutter run --profile`
- DevTools Performance
- DevTools Widget Inspector → Track Widget Rebuilds
- Log sementara pada repository untuk menghitung query (hanya saat pengukuran, bukan kode final)

---

## 9. Rekomendasi urutan implementasi

1. **F-01** — debounce pencarian, hapus `setState` berlebihan, kecilkan cakupan rebuild.
2. **F-02** — pecah `ConsumerWidget` dan gunakan `select`.
3. **F-03** — update state lokal setelah tambah/hapus, hindari `AsyncLoading` saat mutasi.
4. **F-04** — pagination/query SQL, hanya jika data sudah besar.

Setelah setiap langkah, jalankan ulang skenario baseline dan bandingkan. Jangan mengubah beberapa hal sekaligus agar penyebab perbaikan mudah diketahui.

---

## 10. Catatan kepatuhan tugas

- Dokumen ini merekam kondisi **sebelum** optimasi.
- Project Week 10 **tidak disentuh**.
- Implementasi F-01–F-03 dan hasil pengujiannya dicatat di `docs/performance-implementation.md`.
