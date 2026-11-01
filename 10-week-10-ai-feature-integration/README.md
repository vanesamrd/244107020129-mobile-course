# Notes App – Week 10: AI Feature Integration

Aplikasi catatan mobile berbasis Flutter dengan integrasi cerdas **AI Chat Assistant (Google Gemini API)**, penyimpanan kunci API terenkripsi menggunakan **FlutterSecureStorage**, sanitasi privasi pengguna, dan strategi **fallback offline**. Dibangun melanjutkan arsitektur bersih (*Clean Architecture / Feature-First*) dari Week 9 dengan dukungan SQLite dan Riverpod.

---

## 1. Konsep & Arsitektur Integrasi Fitur AI

Fitur AI pada aplikasi ini bertindak sebagai asisten catatan dan belajar mahasiswa (*AI Note & Study Companion*), yang mampu merangkum materi catatan, menyarankan ide judul, menyusun daftar tugas/to-do list, dan menjawab pertanyaan pembelajaran dengan respons terstruktur.

### Diagram Arsitektur Integrasi AI

```
+-----------------------------------------------------------------------+
|                              Flutter UI                               |
|        (NotesScreen, NoteSearchBar, NoteCard, ChatScreen, AI Chips)   |
+-----------------------------------------------------------------------+
        |                                                 ^
        | Request User                                    | Respons Terformat
        v                                                 |
+-----------------------------------------------------------------------+
|                     State Management (Riverpod)                       |
|           (notesProvider, filteredNotesProvider, chatProvider)        |
+-----------------------------------------------------------------------+
        |                                                 ^
        | Sanitasi Privasi & Panggilan                    | Hasil / Fallback
        v                                                 |
+-----------------------------------+             +---------------------+
|        AI Service Layer           |             |    Local Cache /    |
| (AiService - lib/ai/ai_service.dart)| <-------->|  Database (SQLite)  |
+-----------------------------------+             |  (Catatan Tersimpan)|
        |                           |             +---------------------+
        | Secure Storage (Hardware) | HTTPS JSON
        v                           v
+-----------------------+   +-------------------------------------------+
| FlutterSecureStorage  |   |        Google Gemini API Endpoint         |
| (Keychain / KeyStore) |   | (gemini-1.5-flash:generateContent)        |
+-----------------------+   +-------------------------------------------+
```

### Prinsip Utama Integrasi:
1. **Penyimpanan Kunci API Aman**: Kunci API Google Gemini disimpan pada secure hardware storage (`flutter_secure_storage`), tidak pernah di-hardcode ke kode sumber (`lib/`) atau diekspos ke git.
2. **Sanitasi Data Privasi**: Modul `sanitizeInput` secara otomatis mendeteksi dan menyamarkan NIK, nomor telepon, dan email sebelum dikirimkan ke cloud AI API.
3. **Penyimpanan Catatan Langsung**: Respons AI dapat langsung disimpan menjadi catatan baru ke database lokal SQLite dengan satu kali sentuh tombol *"Simpan Catatan"*.
4. **Resiliensi Jaringan & Fallback**: Jika kuota limit (HTTP 429), server error (HTTP 500), atau jaringan putus, pengguna disajikan dialog ramah dan opsi respons cerdas *Mode Offline Fallback*.

---

## 2. Fitur yang Diintegrasikan

- 🤖 **AI Asisten Catatan & Belajar**: Obrolan interaktif dengan Gemini 1.5 Flash langsung di dalam aplikasi.
- ⚡ **Quick Prompt Action Chips**: Pintasan cepat untuk:
  - 💡 *Buat ide judul catatan*
  - 📝 *Ringkas konsep materi*
  - 📅 *Buat to-do list belajar*
  - ✨ *Tips produktivitas kuliah*
- 📥 **Simpan AI ke Catatan Lokal**: Mengonversi saran/ringkasan AI langsung menjadi item catatan SQLite.
- 🔐 **Manajemen API Key In-App**: Antarmuka modal untuk mengisi, menguji koneksi (*Tes Koneksi*), menyimpan, dan menghapus API Key secara aman.
- ⏳ **Indikator Loading Animasi**: Visual feedback status "AI sedang mengetik..." dan indikator loading saat memproses.
- 📋 **Salin Pesan Cepat**: Kemudahan menyalin teks ke clipboard perangkat.
- 🔍 **Fitur Bawaan Week 9**: Search judul catatan real-time, Empty State adaptif, database SQLite lokal, dan Riverpod state.

---

## 3. Bukti Mesin Hijau (Verification & Tests)

Aplikasi telah lulus pengujian statis (**flutter analyze**) dan pengujian dinamis (**flutter test**) dengan **0 warning / 0 error**:

### A. Output `flutter analyze`
```bash
$ flutter analyze
Analyzing 10-week-10-ai-feature-integration...
No issues found! (ran in 1.7s)
```

### B. Output `flutter test`
```bash
$ flutter test
00:00 +0: .../test/search_filter_test.dart
00:01 +7: .../test/widget/empty_state_widget_test.dart
00:02 +18: .../test/ai_service_test.dart
00:02 +28: .../test/widget/chat_screen_test.dart
00:03 +32: All tests passed!
```

**Ringkasan Test Suite (32 skenario pengujian lulus):**
- `test/search_filter_test.dart`: 7 unit test untuk logika filter pencarian catatan.
- `test/widget/empty_state_widget_test.dart`: 5 widget test tampilan empty state.
- `test/ai_service_test.dart`: 16 unit test mencakup sanitasi privasi (NIK, nomor telepon, email), enkripsi secure storage, parsing respons JSON Gemini, error status HTTP (400, 401, 429, 500), timeout, serta verifikasi rule engine offline fallback.
- `test/widget/chat_screen_test.dart`: 4 widget test untuk AppBar, quick prompt chips, pembukaan modal konfigurasi API Key, pembersihan riwayat obrolan, dan penanganan dialog fallback error.

---

## 4. Tabel Risiko dan Mitigasi (Privasi & Biaya)

| Kategori Risiko | Potensi Masalah | Strategi Mitigasi yang Diterapkan |
|---|---|---|
| **Bocor Kunci API** | Kunci API terekspos di repo GitHub publik atau di-decompile dari APK | 1. Kunci API **tidak pernah di-hardcode** di file kode.<br>2. Disimpan terenkripsi di `FlutterSecureStorage` (iOS Keychain / Android EncryptedSharedPreferences).<br>3. Pengguna memasukkan kunci masing-masing via UI Settings. |
| **Bocor Data Privasi Pengguna** | Pengguna tanpa sengaja mengirim NIK, nomor telepon, alamat, atau email ke server AI publik | 1. Implementasi regex rule-based filtering pada `AiService.sanitizeInput()`.<br>2. Data sensitif otomatis dimask menjadi `[NIK DIRAHASIAKAN]`, `[NO TELEPON DIRAHASIAKAN]`, dan `[EMAIL DIRAHASIAKAN]` sebelum dikirim ke API.<br>3. System prompt menginstruksikan AI untuk menolak meminta atau membocorkan data pribadi. |
| **Lonjakan Biaya API (Cost Spike)** | Request berulang tanpa batas menghabiskan kuota atau tagihan berlebih | 1. Menggunakan model efisien berbiaya rendah (`gemini-1.5-flash`).<br>2. Membatasi `maxOutputTokens: 800` pada konfigurasi request.<br>3. Menghindari pemanggilan otomatis di latar belakang (AI hanya dipanggil atas inisiasi aksi pengguna).<br>4. Memanfaatkan penyimpanan lokal SQLite untuk menyimpan output penting tanpa perlu men-generate ulang. |
| **Kegagalan Jaringan / API Down / Rate Limit (429)** | Aplikasi crash atau pengguna frustrasi ketika API tidak merespons | 1. Error handling menyeluruh menangani status 400, 401, 429, 500, hingga timeout jaringan.<br>2. Menampilkan dialog ramah pengguna (*"Layanan AI Sibuk"*).<br>3. Menyediakan mode cadangan (*Offline Fallback*) berbasis heuristik lokal perangkat. |
| **Respons Tidak Relevan / Halusinasi** | AI memberikan saran yang terlalu panjang atau keluar dari konteks catatan | 1. Menggunakan System Prompt terarah yang membatasi jawaban maksimal 2-3 paragraf/poin.<br>2. Quick Prompt Chips untuk memandu pengguna dengan prompt berkualitas. |

---

## 5. Struktur Direktori Proyek

```
10-week-10-ai-feature-integration/
├── lib/
│   ├── ai/
│   │   ├── ai_service.dart              # Service API Gemini, sanitasi, dan offline fallback
│   │   └── ai_provider.dart             # State management Riverpod untuk chat & API key
│   ├── features/
│   │   ├── chat_screen.dart             # UI Chat AI, quick chips, typing indicator, modal API key
│   │   └── notes/
│   │       ├── data/                    # SQLite repository & AppDatabase
│   │       ├── domain/                  # Pure entity Note & search use case
│   │       └── presentation/            # NotesScreen, NoteSearchBar, NoteCard, AddNoteSheet
│   └── main.dart                        # Entry point Flutter & konfigurasi tema Material 3
├── test/
│   ├── ai_service_test.dart             # 16 unit tests: sanitasi data, API Gemini, fallback
│   ├── search_filter_test.dart          # 7 unit tests: logika filter judul catatan
│   ├── widget_test.dart                 # Smoke test dasar
│   └── widget/
│       ├── chat_screen_test.dart        # 4 widget tests: interaksi UI chat, modal API key, fallback
│       └── empty_state_widget_test.dart # 5 widget tests: empty state visual
├── docs/
│   └── ai-log.md                        # Log interaksi prompt sistem, user prompt, sanitasi, dan fallback
├── screenshots/                         # Bukti visual antarmuka dan mesin hijau
├── pubspec.yaml                         # Dependensi (http, flutter_secure_storage, riverpod, sqflite)
└── README.md                            # Dokumentasi lengkap proyek
```

---

## 6. Refleksi

### 1. Fitur AI mana yang Anda integrasikan dan mengapa?
> **Jawaban:**  
> Saya mengintegrasikan **AI Chat & Note Assistant** berbasis Google Gemini API ke dalam aplikasi catatan. Fitur ini dipilih karena memberikan nilai tambah yang sinergis terhadap pencatatan mobile: pengguna tidak hanya mencatat secara pasif, tetapi dapat meminta AI untuk merangkum materi kuliah yang panjang, memberikan ide judul yang menarik, menyusun to-do list tugas, serta menyimpan hasil obrolan AI langsung ke dalam catatan SQLite lokal hanya dengan satu sentuhan.

### 2. Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?
> **Jawaban:**  
> Perlindungan privasi pengguna diterapkan secara bertingkat:
> 1. **Sanitasi Data di Sisi Klien (*Client-Side Sanitization*)**: Metode `sanitizeInput()` memindai teks input pengguna menggunakan ekspresi reguler (Regex) untuk menyamarkan informasi sensitif seperti NIK (16 digit angka), nomor telepon seluler Indonesia, dan alamat email sebelum payload dikirimkan ke cloud endpoint.
> 2. **Penyimpanan Kunci API Terenkripsi**: Token API disimpan menggunakan `FlutterSecureStorage` yang memanfaatkan secure storage tingkat hardware (Keychain pada iOS/macOS dan KeyStore/EncryptedSharedPreferences pada Android), sehingga tidak dapat dicuri melalui reverse-engineering file APK.
> 3. **Instruksi Batasan pada System Prompt**: Model Gemini dibatasi melalui *system instruction* eksplisit agar tidak pernah meminta, mencatat, atau menyebarkan data identitas pribadi pengguna.

### 3. Fallback apa yang Anda sediakan jika layanan AI error?
> **Jawaban:**  
> Kami menyediakan mekanisme fallback berlapis:
> 1. **Penanganan Error Spesifik**: Status kode HTTP 401/403 (kunci belum valid), 429 (kuota rate limit), 500+ (server down), dan timeout jaringan ditangkap dan diterjemahkan menjadi pesan dialog ramah (*"Layanan AI Sibuk"*).
> 2. **Mode Offline Cerdas**: Pengguna dapat menekan tombol *"Gunakan Mode Offline"* pada dialog error. Fungsi `generateOfflineFallback()` pada `AiService` akan secara otomatis menganalisis intensi prompt pengguna (apakah meminta ringkasan, ide judul, atau to-do list) dan menyajikan panduan terstruktur secara instan tanpa memerlukan koneksi internet.
> 3. **Independensi Data Lokal**: Kegagalan pada layanan cloud AI sama sekali tidak mengganggu fungsi utama aplikasi (pembuatan, pembacaan, pencarian, dan penghapusan catatan lokal di SQLite tetap berjalan 100% normal).

### 4. Satu hal yang Anda pelajari tentang UX fitur AI di mobile?
> **Jawaban:**  
> Satu pelajaran terpenting adalah bahwa **fitur AI di mobile harus transparan, responsif, dan mudah ditindaklanjuti**. Pengguna ponsel memiliki ekspektasi waktu respons yang cepat dan ruang layar yang terbatas. Oleh karena itu:
> - Menyediakan **Quick Prompt Chips** sangat membantu pengguna karena mereka tidak perlu mengetik panjang di keyboard kecil ponsel.
> - Menyediakan **Typing Indicator** animasi memberikan kepastian visual bahwa sistem sedang bekerja dan tidak *freeze*.
> - Menyediakan tombol **"Simpan Catatan"** langsung pada bubble obrolan AI menjembatani hasil AI dengan alur kerja aplikasi secara mulus (*seamless actionability*), sehingga output AI tidak sekadar berhenti sebagai obrolan sementara.

---

## 7. Panduan Menjalankan Aplikasi

### Prasyarat
- Flutter SDK (versi >= 3.12.0)
- Emulator Android / iOS Simulator / macOS desktop runner

### Langkah Menjalankan:
```bash
# 1. Masuk ke direktori proyek
cd 10-week-10-ai-feature-integration

# 2. Unduh paket dependensi
flutter pub get

# 3. Jalankan pengujian statis dan unit test
flutter analyze
flutter test

# 4. Jalankan aplikasi pada perangkat / emulator
flutter run
```

### Konfigurasi API Key:
1. Jalankan aplikasi di emulator atau perangkat.
2. Buka layar **AI Asisten Catatan** melalui ikon kilau (✨) di kanan atas AppBar atau banner AI.
3. Ketuk ikon kunci (🔑) di pojok kanan atas.
4. Masukkan Google Gemini API Key Anda (dapat diperoleh gratis di [Google AI Studio](https://aistudio.google.com/)).
5. Tekan tombol **Tes Koneksi** untuk memverifikasi keabsahan kunci.
6. Tekan **Simpan**. Kunci akan tersimpan secara terenkripsi dan siap digunakan.
