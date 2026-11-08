# Week 11 — Performance Report

**Project:** `11-week-11-performance-optimization`
**Status implementasi:** F-01, F-02, dan F-03 sudah diterapkan.
**Status pengukuran after:** screenshot profiling tersedia, tetapi export data mentah (JSON/CSV) belum tersedia; metrik after belum dapat dihitung.

> **Penting:** laporan ini memakai data baseline yang diberikan secara terpisah. Repository sekarang berisi enam screenshot PNG di `screenshots/`, tetapi tidak ada export DevTools Performance (`.json`) atau CSV memory. Screenshot bukan data mentah dan tidak memuat total frame/janky frame. Karena itu laporan ini **tidak mengklaim** bahwa performa sudah meningkat.

---

## 1. Pendahuluan

Project Week 11 adalah aplikasi Notes App berbasis Flutter yang merupakan salinan mandiri dari project Week 10 (AI Feature Integration). Aplikasi memiliki fitur catatan lokal berbasis SQLite, pencarian judul catatan, serta layar AI Assistant untuk berinteraksi dengan Gemini API.

Fokus Week 11 adalah optimasi performa. Tiga area yang dioptimasi:

1. **Pencarian catatan** — mengurangi pekerjaan pada setiap ketikan.
2. **Rebuild widget dengan Riverpod** — mempersempit cakupan widget yang dibangun ulang.
3. **Operasi tambah/hapus catatan** — menghindari pembacaan ulang seluruh tabel setelah mutasi.

Laporan ini disusun berdasarkan:

- source code Week 11 saat ini;
- dokumen `docs/performance-findings.md` dan `docs/performance-implementation.md`;
- data baseline profiling yang diberikan;
- hasil verifikasi `flutter analyze`, `flutter test`, dan build macOS.

---

## 2. Tujuan Optimasi

Tujuan optimasi pada Week 11:

1. Mengurangi jumlah pembaruan state dan pekerjaan filter saat pengguna mengetik di kolom pencarian.
2. Mengurangi rebuild widget yang tidak membutuhkan data yang berubah.
3. Menghilangkan query `SELECT` seluruh tabel setelah setiap tambah/hapus catatan.
4. Menjaga perilaku fitur tetap sama: pencarian, ikon clear, tambah catatan, hapus catatan, chat AI, dan penyimpanan SQLite.
5. Menyediakan dokumentasi yang jujur tentang bukti sebelum/sesudah optimasi.

Optimasi **bukan** bertujuan mengubah desain UI, skema database, atau dependency.

---

## 3. Lingkungan Pengujian

| Komponen | Keterangan |
|---|---|
| Flutter | 3.44.5 (stable) |
| Dart | 3.12.2 |
| Sistem operasi | macOS 26.5.2 (darwin-arm64) |
| Xcode | 26.6 |
| Refresh rate baseline | 60 Hz |
| Frame budget 60 Hz | ±16,67 ms per frame |
| Target build verifikasi | macOS debug |
| Data source profiling | ringkasan baseline yang diberikan; file mentah tidak ada di repo |

Catatan:

- Detail perangkat yang dipakai saat baseline tidak tercatat di repository. Agar perbandingan adil, pengukuran *after* harus memakai perangkat/emulator, refresh rate, dan skenario yang sama.
- Baseline menyebut refresh rate 60 Hz. Jika perangkat after memakai refresh rate berbeda, hasil frame time tidak bisa dibandingkan langsung.

---

## 4. Baseline Metrics

Data baseline yang tersedia:

| Metrik | Nilai |
|---|---:|
| Total frames | 418 |
| Normal frames | 308 |
| Janky frames | 110 |
| Jank rate | 26,3% |
| Refresh rate | 60 Hz |

Verifikasi aritmetika:

- `308 + 110 = 418` — sesuai dengan total frame.
- `110 / 418 × 100% = 26,3%` — sesuai dengan jank rate yang dilaporkan.

Interpretasi:

- Dari 418 frame yang direkam, 110 frame melewati batas frame budget 60 Hz.
- Jank rate 26,3% berarti sekitar satu dari empat frame tergolong janky.
- **Total frame tidak boleh dibandingkan sendirian.** Jumlah frame sangat bergantung pada durasi rekaman dan skenario. Pembandingan harus memakai jank rate, frame time (misalnya p95), dan jumlah janky frame pada skenario yang sama.

**Sumber data:** ringkasan baseline yang diberikan. Screenshot PNG profiling tersedia, tetapi tidak ada file JSON/CSV hasil export DevTools di repository, sehingga angka baseline tidak dapat diverifikasi ulang dari file mentah.

---

## 5. Temuan Profiling Sebelum Optimasi

Baseline menunjukkan 110 janky frame dari 418 frame, tetapi **tidak memecah** jank berdasarkan skenario. Karena itu, baseline belum bisa membuktikan berapa persen jank berasal dari pencarian, rebuild Riverpod, atau CRUD. Temuan berikut berasal dari analisis kode dan menjadi kandidat penyebab yang perlu diuji.

### 5.1 F-01 — Pencarian memicu rebuild dan filter berlebihan

Sebelum optimasi:

- `NoteSearchBar` memanggil `setState()` dan mengubah `searchQueryProvider` pada setiap karakter.
- `NotesScreen` me-watch query, daftar hasil filter, dan daftar lengkap catatan.
- Setiap perubahan query memicu filter `O(n)` ke seluruh catatan.

Dampak yang mungkin:

- pekerjaan filter dan rebuild meningkat sebanding dengan frekuensi ketikan;
- widget yang tidak berubah ikut dibangun ulang;
- pada jumlah catatan besar, kerja di UI thread bertambah.

Yang belum dibuktikan:

- Baseline tidak mencatat skenario “mengetik cepat” secara terpisah.
- Belum ada data after yang dapat dihitung untuk menunjukkan penurunan jank pada skenario tersebut.

### 5.2 F-02 — Cakupan watch Riverpod terlalu lebar

Sebelum optimasi:

- `NotesScreen` me-watch `filteredNotesProvider`, `notesProvider`, dan `searchQueryProvider` sekaligus.
- `ChatScreen` me-watch seluruh `ChatState`.

Dampak yang mungkin:

- perubahan daftar catatan membangun ulang header, banner, search bar, dan daftar;
- perubahan `messages`, `isLoading`, atau `hasApiKey` membangun ulang seluruh body `ChatScreen`;
- pekerjaan `build()` dan diff elemen bertambah walaupun hasil visual sama.

Yang belum dibuktikan:

- Baseline tidak mencatat jumlah rebuild per widget.
- Dampak rebuild terhadap jank bergantung pada kompleksitas subtree dan perangkat.

### 5.3 F-03 — Tambah/hapus catatan membaca ulang seluruh tabel

Sebelum optimasi:

- Setelah `save()` atau `delete()`, `NotesNotifier` memanggil `reload()`.
- `reload()` mengubah state menjadi `AsyncLoading`, lalu memanggil `fetchAll()`.
- `fetchAll()` membaca seluruh tabel dan memetakan ulang semua baris.

Dampak yang mungkin:

- satu query `SELECT` penuh per mutasi;
- daftar sempat berubah menjadi spinner;
- item yang terlihat dibangun ulang setelah loading selesai.

Yang belum dibuktikan:

- Baseline tidak mencatat durasi operasi tambah/hapus atau jumlah query.
- Belum ada data after yang dapat dihitung untuk mengukur pengurangan waktu operasi.

### 5.4 Catatan tentang baseline

Baseline berguna sebagai gambaran awal, tetapi belum cukup untuk atribusi penyebab. Agar analisis lebih kuat, baseline idealnya mencatat:

- skenario yang direkam (search, CRUD, chat, scroll);
- jumlah catatan yang dipakai;
- p95/p99 frame time;
- jumlah rebuild per widget;
- jumlah query SQLite saat mutasi.

---

## 6. Optimasi yang Diterapkan Beserta Alasan

### 6.1 Ringkasan perubahan

| ID | Optimasi | File utama | Alasan |
|---|---|---|---|
| F-01 | Debounce 250 ms, hilangkan `setState()` pencarian | `search_bar_widget.dart` | Mengurangi filter dan rebuild per karakter |
| F-02 | Pecah widget dan gunakan `select` | `notes_screen.dart`, `chat_screen.dart` | Rebuild hanya pada subtree yang datanya berubah |
| F-03 | Update state lokal untuk tambah/hapus | `notes_provider.dart` | Menghindari `fetchAll()` dan transisi loading setelah mutasi |

Tidak ada perubahan pada:

- `pubspec.yaml` dan dependency;
- skema database/tabel;
- desain atau tata letak UI;
- source code Week 10.

### 6.2 F-01 — Debouncing Search

**Masalah sebelum optimasi**

Setiap karakter langsung mengubah `searchQueryProvider` dan memanggil `setState()`. Filter dijalankan ulang dan widget lain ikut rebuild.

**Perubahan**

- Debounce 250 ms menggunakan `Timer` di `search_bar_widget.dart`.
- Timer lama dibatalkan saat ada ketikan baru.
- Timer dibatalkan di `dispose()` untuk mencegah timer aktif setelah widget hilang.
- `setState()` untuk pencarian dihapus.
- Status ada/tidaknya teks memakai `ValueNotifier<bool>` dan `ValueListenableBuilder`, sehingga hanya bagian ikon clear/TextField yang perlu yang dibangun ulang.
- Ikon clear tetap berfungsi dan langsung mengosongkan controller serta query.
- Perubahan query dari luar search bar disinkronkan ke controller melalui `ref.listen`.

**Mengapa mengurangi pekerjaan tidak perlu**

- Filter tidak dijalankan pada setiap karakter, tetapi maksimal sekali setelah pengguna berhenti mengetik 250 ms.
- Perubahan query tidak membangun ulang seluruh `NotesScreen`.
- Rebuild untuk ikon clear tidak lagi memakai `setState()` seluruh search bar.

**Trade-off**

- Hasil pencarian muncul dengan jeda kecil ±250 ms. Ini disengaja.
- Ada tambahan kompleksitas lifecycle `Timer` dan sinkronisasi controller dengan provider.

### 6.3 F-02 — Mempersempit Widget Rebuild dengan Riverpod

**Masalah sebelum optimasi**

`NotesScreen` dan `ChatScreen` me-watch state yang terlalu luas, sehingga perubahan kecil membangun ulang banyak widget yang tidak berubah.

**Perubahan**

`NotesScreen` dipecah menjadi:

- `_NotesHeader` — hanya me-watch jumlah catatan melalui `notesProvider.select(...)`;
- `_AiBanner` — hanya me-watch status “sedang mencari”;
- `_SearchResultChip` — hanya menangani query dan jumlah hasil;
- `_NotesList` — hanya menangani daftar hasil filter dan empty state.

`ChatScreen` dipecah menjadi:

- `_ChatStatus` — hanya me-watch `hasApiKey`;
- `_ChatMessages` — hanya me-watch `messages` dan `isLoading`;
- `_QuickPromptsBar` — hanya me-watch `isLoading`;
- `_ChatInputBar` — hanya me-watch `isLoading`.

Widget statis juga memakai `const` bila memungkinkan.

**Mengapa mengurangi pekerjaan tidak perlu**

- `select` hanya memberi notifikasi bila bagian yang dipilih berubah.
- Perubahan query tidak membangun ulang header, banner, atau input chat.
- Perubahan pesan AI tidak membangun ulang seluruh `ChatScreen`.
- Rebuild terbatas pada subtree yang benar-benar membutuhkan data.

**Trade-off**

- Struktur kode menjadi lebih banyak widget kecil.
- Jumlah file/class bertambah, sehingga navigasi kode sedikit lebih kompleks.
- `select` perlu dipakai dengan benar agar tidak menambah kompleksitas tanpa manfaat.

### 6.4 F-03 — Optimasi CRUD Lokal

**Masalah sebelum optimasi**

Setiap tambah/hapus memanggil `reload()`, yang mengubah state menjadi loading lalu membaca ulang seluruh tabel melalui `fetchAll()`.

**Perubahan**

- `addNote()` memakai `savedNote` hasil `save()` dan menambahkannya ke state lokal di urutan paling atas.
- `deleteNote()` menghapus item dari state berdasarkan `id`, tanpa membaca ulang tabel.
- `AsyncData` dipertahankan selama mutasi agar daftar tidak berubah menjadi spinner.
- State sebelumnya disimpan dan dipulihkan jika `save()` atau `delete()` gagal.
- Error tetap dilempar kembali agar pemanggil dapat menanganinya.
- `reload()` tetap tersedia untuk refresh eksplisit, tetapi tidak dipanggil setelah tambah/hapus.

**Mengapa mengurangi pekerjaan tidak perlu**

- Satu mutasi tidak lagi diikuti query `SELECT` seluruh tabel.
- Tidak ada mapping ulang seluruh baris.
- Tidak ada transisi `AsyncData → AsyncLoading → AsyncData` yang memicu spinner dan rebuild daftar.
- Update lokal hanya mengubah list di memori.

**Trade-off**

- Perlu logika rollback agar state UI dan database tetap konsisten jika operasi gagal.
- Jika nanti ada banyak mutasi bersamaan, diperlukan strategi tambahan (antrean/batch), karena update lokal mengasumsikan urutan operasi yang sederhana.

---

## 7. Hasil Profiling Setelah Optimasi

### 7.1 Status data after

Repository sekarang berisi **enam screenshot PNG** di `screenshots/`, tetapi tidak berisi export data mentah DevTools Performance (`.json`) atau CSV memory.

Audit file yang dilakukan:

| Bukti yang dicari | Hasil audit |
|---|---|
| Export DevTools Performance (`.json`) | Tidak ditemukan |
| File CSV profiling after | Tidak ditemukan |
| Screenshot timeline | 5 PNG frame chart ditemukan |
| Screenshot memory | 1 PNG memory chart ditemukan |
| Folder `screenshots/` | 6 PNG + `.gitkeep` |

File yang diaudit (waktu diambil dari nama file):

| File | Waktu | Isi visual |
|---|---|---|
| `Tangkapan Layar 2026-11-08 pukul 16.07.01.png` | 16.07.01 | Frame chart; label frame terlihat 2–38; banyak bar merah; average FPS jendela 7 |
| `Tangkapan Layar 2026-11-08 pukul 16.08.03.png` | 16.08.03 | Frame chart; label frame terlihat 118–310; dominan bar merah; average FPS jendela 10 |
| `Tangkapan Layar 2026-11-08 pukul 16.11.19.png` | 16.11.19 | Frame chart; label frame terlihat 674–706; semua bar biru; average FPS jendela 24 |
| `Tangkapan Layar 2026-11-08 pukul 16.12.15.png` | 16.12.15 | Frame chart; label frame terlihat 453–504; banyak bar merah; average FPS jendela 24 |
| `Tangkapan Layar 2026-11-08 pukul 16.47.34.png` | 16.47.34 | Frame chart; label frame terlihat 45–482; banyak bar merah; average FPS jendela 9 |
| `Tangkapan Layar 2026-11-08 pukul 16.54.05.png` | 16.54.05 | Memory chart; titik biru mendekati skala 500 MB dan garis putus-putus oranye di sekitar skala 300 MB; tidak ada tabel angka |

Keterbatasan data:

- screenshot adalah **crop frame chart**, bukan export data mentah;
- sumbu X menampilkan jendela frame yang terlihat, bukan total frame satu sesi rekaman;
- tidak ada ringkasan `total frames`, `normal frames`, `janky frames`, atau `jank rate`;
- angka **average FPS** pada screenshot hanya berlaku untuk jendela yang terlihat dan tidak sama dengan jank rate;
- tidak ada label `before`/`after` atau nama skenario pada file;
- timestamp menunjukkan dua kelompok waktu, yaitu 16.07–16.12 dan 16.47–16.54, tetapi timestamp saja tidak membuktikan pasangan skenario yang setara.

Karena itu:

- jumlah frame after **tidak dapat dihitung secara sah** dari screenshot;
- jumlah janky frame after **tidak dapat dihitung**;
- jumlah normal frame after **tidak dapat dihitung**;
- jank rate after **tidak dapat dihitung**;
- perbandingan before/after **tidak dapat dibuat**;
- penurunan jank **tidak boleh diklaim**.

### 7.2 Tabel pembandingan

Tabel berikut sengaja tidak diisi dengan angka after karena screenshot tidak menyediakan total frame:

| Metrik | Baseline | After | Delta | Alasan |
|---|---:|---:|---:|---|
| Total frames | 418 | tidak dapat dihitung | — | screenshot tidak memuat total rekaman |
| Normal frames | 308 | tidak dapat dihitung | — | tidak ada ringkasan normal frames |
| Janky frames | 110 | tidak dapat dihitung | — | jumlah bar merah pada satu jendela bukan total |
| Jank rate | 26,3% | tidak dapat dihitung | — | pembilang dan penyebut after tidak tersedia |
| p95 frame time | tidak tercatat | tidak dapat dihitung | — | perlu data timeline/export |
| Jumlah rebuild `NotesScreen` | tidak tercatat | tidak dapat dihitung | — | perlu Widget Inspector |
| Jumlah query saat tambah/hapus | tidak tercatat | tidak dapat dihitung | — | perlu log/test repository |

Observasi visual frame time (bukan metrik final):

- Bar biru berada di bawah ambang 16,67 ms untuk 60 Hz; bar merah melewati ambang tersebut.
- Jendela 16.11.19 terlihat seluruhnya biru, sedangkan jendela 16.08.03 dan 16.47.34 masih menunjukkan banyak bar merah.
- Tanpa durasi rekaman, total frame, label skenario, dan pasangan before/after yang setara, observasi ini tidak bisa dipakai untuk menghitung delta jank rate.

Rumus jank rate yang tetap harus dipakai setelah data mentah tersedia:

```text
jank rate = (jumlah frame janky / total frame) × 100%
```

Contoh baseline:

```text
110 / 418 × 100% = 26,3%
```

### 7.3 Cara melengkapi data after

Screenshot saja tidak cukup. Untuk menghitung metrik after secara sah:

1. Jalankan aplikasi dalam mode profile:
   ```bash
   flutter run --profile
   ```
2. Buka DevTools → **Performance**.
3. Rekam skenario yang sama dengan baseline. Minimal:
   - buka aplikasi dan tunggu daftar termuat;
   - scroll daftar;
   - ketik 20–30 karakter di pencarian;
   - hapus pencarian;
   - tambah satu catatan;
   - hapus satu catatan;
   - buka layar AI dan kirim satu pesan.
4. Catat durasi rekaman, jumlah catatan, perangkat, dan refresh rate.
5. Export hasil Performance ke file **JSON**; screenshot saja tidak menyimpan total frame/janky frame.
6. Beri nama file dengan label skenario dan before/after, misalnya:
   - `screenshots/before-search-performance.json`
   - `screenshots/after-search-performance.json`
   - `screenshots/before-search-timeline.png`
   - `screenshots/after-search-timeline.png`
7. Hitung dari export:
   - total frames;
   - janky frames (frame di atas 16,67 ms untuk 60 Hz);
   - jank rate;
   - p95 frame time;
   - jumlah rebuild widget (Widget Inspector → Track Widget Rebuilds).

Tanpa langkah di atas, laporan hanya bisa menyimpulkan bahwa optimasi **sudah diterapkan dan lolos pengujian fungsional**, bukan bahwa performa sudah meningkat.

---

## 8. Analisis Memory Profiling

### 8.1 Sumber data

Data memory yang tersedia adalah ringkasan yang diberikan:

| Metrik | Nilai |
|---|---:|
| Total instance | 728 |
| Total ukuran objek tercatat | 13.664 bytes |
| New Space | 10.016 bytes |
| Old Space | 3.648 bytes |
| Matrix4 | 529 instance, 8.464 bytes |
| Vector4 | 85 instance, 1.360 bytes |

**Tidak ada file CSV memory di repository.** Angka di atas berasal dari ringkasan yang diberikan, bukan dari file mentah yang diaudit langsung.

Screenshot memory yang tersedia adalah `screenshots/Tangkapan Layar 2026-11-08 pukul 16.54.05.png`. Isinya hanya grafik memory: titik biru mendekati skala 500 MB dan garis putus-putus oranye di sekitar skala 300 MB. Screenshot tersebut tidak memuat tabel instance, ukuran objek, atau angka retained size, sehingga tidak bisa dipakai untuk menghitung metrik memory after secara tepat.

### 8.2 Perhitungan turunan

- New Space: `10.016 / 13.664 × 100% = 73,3%`
- Old Space: `3.648 / 13.664 × 100% = 26,7%`
- Matrix4: `8.464 / 13.664 × 100% = 61,9%`
- Vector4: `1.360 / 13.664 × 100% = 10,0%`
- Matrix4 + Vector4: `614 instance` dan `9.824 bytes` (±71,9% dari ukuran objek tercatat)

Objek dengan penggunaan terbesar adalah **Matrix4**:

- 529 instance;
- 8.464 bytes;
- sekitar 61,9% dari total ukuran objek yang tercatat.

Vector4 berada di urutan berikutnya:

- 85 instance;
- 1.360 bytes;
- sekitar 10,0% dari total ukuran objek yang tercatat.

### 8.3 Interpretasi yang benar

- “Total ukuran objek tercatat 13.664 bytes” **bukan total RAM aplikasi**. Nilai itu hanya mencakup objek yang masuk ke pencatatan CSV/snapshot.
- Snapshot tunggal **tidak cukup** untuk menyimpulkan memory leak.
- `Matrix4` dan `Vector4` umumnya terkait transformasi/vektor pada rendering dan animasi. Jumlah besar belum tentu leak; bisa merupakan kondisi normal saat snapshot diambil.
- Untuk menyimpulkan leak, perlu:
  1. beberapa snapshot pada waktu berbeda;
  2. memastikan garbage collection sudah berjalan;
  3. melihat tren jumlah instance/retained size;
  4. memeriksa retainer/stack objek yang terus bertambah.

### 8.4 Perbandingan memory before/after

Tidak dapat dilakukan secara sah. Screenshot memory terakhir memang tersedia, tetapi hanya berupa grafik tanpa tabel instance/retained size dan tanpa label `before`/`after`. Grafik tersebut juga tidak bisa menggantikan CSV atau snapshot memory mentah.

Agar bisa dibandingkan:

1. Ambil snapshot memory pada skenario yang sama sebelum dan sesudah optimasi.
2. Tunggu GC sebelum snapshot.
3. Lakukan operasi berulang (misalnya buka/tutup pencarian, tambah/hapus catatan) lalu ambil snapshot lagi.
4. Export data memory ke CSV atau simpan tabel snapshot, bukan hanya screenshot grafik.
5. Bandingkan jumlah instance dan retained size `Matrix4`, `Vector4`, serta total objek tercatat.
6. Jangan menyimpulkan leak dari satu snapshot atau dari kenaikan kecil yang masih dalam siklus normal.

---

## 9. Hasil Verifikasi Flutter Analyze dan Flutter Test

Verifikasi dijalankan di folder `11-week-11-performance-optimization`:

```bash
flutter analyze
flutter test
flutter build macos --debug
```

Hasil terbaru:

| Perintah | Hasil |
|---|---|
| `flutter analyze` | **No issues found** |
| `flutter test` | **40 tests passed** |
| `flutter build macos --debug` | **Berhasil** membuat `notes_app.app` |
| `flutter pub get` | Tidak diperlukan; tidak ada dependency baru |

Rincian tes terkait optimasi:

- `test/search_bar_debounce_test.dart` — 3 tes:
  - query baru diperbarui setelah 250 ms;
  - ikon clear mengosongkan teks dan query;
  - clear dari luar search bar ikut mengosongkan controller.
- `test/notes_provider_test.dart` — 4 tes:
  - tambah catatan tidak memanggil `fetchAll()` ulang;
  - tambah catatan memulihkan state saat `save` gagal;
  - hapus catatan tidak memanggil `fetchAll()` ulang;
  - hapus catatan memulihkan state saat `delete` gagal.
- `test/notes_screen_search_test.dart` — 1 tes integrasi:
  - daftar terfilter setelah debounce;
  - clear mengembalikan seluruh daftar.

Verifikasi ini membuktikan **kebenaran fungsional**, bukan peningkatan performa. Peningkatan performa hanya boleh disimpulkan setelah data profiling after tersedia.

---

## 10. Refleksi

### 10.1 Optimasi paling berdampak dan alasannya

Berdasarkan data profiling yang tersedia, **belum bisa ditentukan optimasi mana yang paling terlihat dampaknya**. Screenshot performance dengan waktu paling akhir (`16.47.34`) masih menampilkan banyak bar merah, tetapi screenshot tersebut tidak memuat total frame, tidak berlabel `after`, dan tidak menunjukkan skenario yang sama dengan baseline. Karena itu tidak ada dasar pengukuran untuk mengurutkan dampak F-01, F-02, dan F-03.

Secara penalaran kode, **F-01 (debouncing search)** adalah kandidat terkuat untuk pengalaman mengetik:

- pencarian adalah interaksi berulang dengan frekuensi tinggi;
- sebelum optimasi, setiap karakter memicu perubahan state, filter seluruh daftar, dan rebuild beberapa widget;
- debounce mengurangi jumlah pekerjaan tersebut secara langsung.

Namun, **F-03** juga memiliki dampak struktural yang jelas: satu query `SELECT` seluruh tabel dihilangkan dari setiap tambah/hapus, dan daftar tidak lagi berubah menjadi loading. Frekuensinya lebih rendah daripada mengetik, tetapi penghematan per operasinya lebih mudah dibuktikan.

Kesimpulan jujur: secara penalaran kode, F-01 paling berdampak pada pengalaman mengetik, sedangkan F-03 paling jelas mengurangi query database. Berdasarkan data profiling yang ada, ini **bukan klaim pengukuran** dan belum bisa diurutkan secara empiris.

### 10.2 Cara memverifikasi optimasi bukan placebo

Optimasi bukan placebo jika:

1. Skenario before dan after sama: perangkat, refresh rate, jumlah catatan, durasi rekaman, dan urutan interaksi.
2. Metrik yang dibandingkan tepat: jank rate, p95 frame time, jumlah janky frames, jumlah rebuild per widget, dan jumlah query.
3. Ada bukti pekerjaan yang benar-benar hilang:
   - jumlah query `fetchAll` tidak bertambah setelah tambah/hapus;
   - query search hanya berubah setelah debounce;
   - `_NotesHeader` tidak rebuild saat query berubah.
4. Perubahan fungsional tetap benar: 40 tes lulus, pencarian dan CRUD berjalan.
5. Hasil after menunjukkan perbedaan yang konsisten, bukan satu frame kebetulan.

Jika after tidak menunjukkan perbedaan, jangan mengklaim peningkatan. Bisa jadi bottleneck bukan di area yang dioptimasi, atau data uji terlalu kecil.

### 10.3 Trade-off kompleksitas kode dan performa

Setiap optimasi menambah kompleksitas:

- **Debounce:** menambah `Timer`, lifecycle `dispose`, dan sinkronisasi controller/provider. Ada jeda 250 ms sebelum hasil filter berubah.
- **Pemecahan widget:** menambah jumlah class dan file. Membuat alur data lebih terpisah, tetapi menuntut pemahaman `select` dan batas rebuild.
- **Update state lokal + rollback:** menambah logika pemulihan state. Jika operasi database gagal, UI harus kembali konsisten. Ini lebih rumit daripada sekadar memanggil `reload()`.
- **Pagination/SQL search (belum diterapkan):** akan menambah kompleksitas repository, tetapi mungkin diperlukan jika data besar.

Kompleksitas ini layak jika ada bukti masalah performa dan optimasi menghasilkan perbedaan yang terukur. Jika data kecil dan tidak ada jank, kompleksitas tambahan bisa lebih merugikan daripada manfaatnya.

### 10.4 Kapan premature optimization harus dihindari

Premature optimization terjadi ketika optimasi dilakukan sebelum ada bukti masalah. Hindari jika:

- belum ada baseline atau profiling;
- jumlah data masih kecil dan aplikasi terasa lancar;
- perubahan hanya berdasarkan dugaan, bukan bukti;
- optimasi membuat kode jauh lebih rumit tanpa metrik yang membaik;
- belum ada cara mengukur dampaknya.

Urutan yang lebih aman:

1. Ukur baseline.
2. Identifikasi bottleneck dari data.
3. Optimasi satu area.
4. Ukur ulang dengan skenario yang sama.
5. Pertahankan hanya jika ada manfaat yang terukur dan trade-off-nya masuk akal.

---

## 11. Kesimpulan

1. F-01, F-02, dan F-03 sudah diterapkan pada project Week 11 tanpa mengubah dependency, skema database, desain UI, atau project Week 10.
2. Baseline menunjukkan 110 janky frame dari 418 frame, dengan jank rate 26,3% pada refresh rate 60 Hz. Baseline ini menunjukkan adanya ruang optimasi, tetapi tidak memecah penyebab jank per skenario.
3. Verifikasi fungsional berhasil:
   - `flutter analyze` → No issues found;
   - `flutter test` → 40 tests passed;
   - build macOS debug → berhasil.
4. **Screenshot profiling after tersedia, tetapi data mentahnya tidak.** Enam screenshot PNG ditemukan di `screenshots/`, namun tidak ada export DevTools Performance (`.json`) atau CSV memory. Karena screenshot frame chart tidak memuat total frame/janky frame, laporan ini tidak menghitung frame after, tidak menghitung jank rate after, dan tidak mengklaim peningkatan performa.
5. Data memory yang tersedia menunjukkan 728 instance dan 13.664 bytes objek tercatat, dengan Matrix4 sebagai objek terbesar (529 instance, 8.464 bytes). Angka ini bukan total RAM aplikasi dan bukan bukti memory leak. Screenshot memory terakhir hanya berupa grafik, bukan tabel CSV, sehingga belum bisa dipakai untuk membandingkan memory before/after.
6. Untuk menyelesaikan evaluasi performa, diperlukan export DevTools Performance after (JSON), export/snapshot memory after (CSV/tabel), serta label skenario dan before/after yang jelas. Screenshot saja tidak cukup.

---

## Lampiran — Checklist Data yang Masih Kurang

| Data yang kurang | Cara melengkapi |
|---|---|
| Export DevTools Performance after (JSON) | `flutter run --profile` → DevTools Performance → rekam skenario → export |
| Jumlah frame after | Baca dari timeline DevTools atau hitung dari export |
| Jumlah janky frame after | Filter frame di atas 16,67 ms pada refresh 60 Hz |
| Jank rate after | `(janky after / total after) × 100%` |
| p95 frame time after | Ambil dari DevTools/timeline |
| Screenshot timeline before | Sudah ada 4 PNG awal (16.07–16.12), tetapi belum berlabel `before`; beri nama sesuai skenario |
| Screenshot timeline after | Sudah ada 1 PNG performa (16.47.34), tetapi belum berlabel `after`; beri nama sesuai skenario |
| Screenshot memory before/after | Sudah ada 1 PNG memory (16.54.05); masih perlu pasangan `before`/`after` berlabel dan tabel angka |
| CSV memory mentah | Belum ada; export dari DevTools Memory/DevTools CSV jika tersedia |
| Jumlah rebuild per widget | DevTools Widget Inspector → Track Widget Rebuilds → catat `_NotesHeader`, `_NotesList`, `ChatScreen`, `_ChatMessages` |
| Jumlah query SQLite per mutasi | Test repository atau log sementara saat profiling |

Setelah data tersebut tersedia, isi tabel pada Bagian 7.2 dan Bagian 8.4, lalu perbarui kesimpulan hanya jika data after benar-benar mendukung.
