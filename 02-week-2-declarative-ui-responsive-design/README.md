# Week 2 — Declarative UI & Responsive Design

## Academic Overview Dashboard

Project ini merupakan tugas Week 2 pada mata kuliah Mobile Development menggunakan Flutter.

Pada tugas ini, aplikasi dashboard yang sebelumnya masih sederhana dikembangkan menjadi **Academic Overview Dashboard**. Dashboard digunakan untuk menampilkan informasi singkat mengenai data akademik mahasiswa.

Selain membuat tampilan dashboard, tugas ini juga menerapkan konsep responsive design, perubahan light/dark mode, penggunaan reusable widget, dan accessibility.

---

## Informasi Mahasiswa

- **Nama:** Vanesa Mardiana Putri
- **NIM:** 244107020129
- **Kelas:** TI-3G

---

## Deskripsi Project

Academic Overview Dashboard merupakan aplikasi sederhana yang menampilkan beberapa informasi akademik mahasiswa dalam bentuk card.

Informasi yang ditampilkan terdiri dari:

- Assignments
- Attendance
- Portfolio
- Current Week

Selain itu, terdapat profile header yang menampilkan nama, NIM, dan kelas mahasiswa.

Tampilan dashboard dibuat responsive. Jadi, ketika ukuran layar berubah, susunan card juga akan menyesuaikan.

Pada layar yang lebih sempit, card ditampilkan dalam **satu kolom**, sedangkan pada layar yang lebih lebar card ditampilkan dalam **dua kolom**.

Aplikasi juga memiliki toggle untuk berpindah antara **light mode** dan **dark mode**.

---

## Tujuan

Tujuan dari pengerjaan tugas ini adalah untuk memahami dan menerapkan beberapa konsep Flutter, yaitu:

1. Membuat UI menggunakan widget Flutter.
2. Menggunakan `Row`, `Column`, `Expanded`, dan `Container`.
3. Membuat layout yang responsive.
4. Menggunakan `LayoutBuilder` untuk menentukan jumlah kolom berdasarkan ukuran layar.
5. Menggunakan theme light dan dark.
6. Membuat widget yang dapat digunakan kembali.
7. Menambahkan accessibility menggunakan `Semantics`.
8. Membuat widget test untuk mengecek responsive layout.

---

# Implementasi

## 1. Profile Header

Bagian atas dashboard digunakan untuk menampilkan informasi mahasiswa.

Informasi yang ditampilkan adalah:

```text
Vanesa Mardiana Putri
244107020129 • TI-3G
```

Pada bagian ini digunakan beberapa widget seperti:

- `Container`
- `Row`
- `Column`
- `Expanded`
- `CircleAvatar`

`Expanded` digunakan agar bagian informasi mahasiswa dapat menggunakan ruang yang tersedia tanpa membuat layout menjadi terlalu sempit.

---

## 2. Information Card

Dashboard memiliki empat card informasi:

| Informasi | Nilai |
|---|---|
| Assignments | 8 |
| Attendance | 92% |
| Portfolio | Ready |
| Current week | 02 |

Daripada membuat setiap card secara terpisah, card dibuat menjadi widget reusable bernama `InfoCard`.

Contohnya:

```dart
const InfoCard(
  title: 'Assignments',
  value: '8',
)
```

Dengan cara ini, struktur card cukup dibuat satu kali dan dapat digunakan untuk beberapa informasi yang berbeda.

---

## 3. Responsive Layout

Responsive layout dibuat menggunakan `LayoutBuilder`.

Breakpoint yang digunakan pada project ini adalah:

```dart
const kWideBreakpoint = 700.0;
```

Kemudian jumlah kolom ditentukan berdasarkan lebar layar:

```dart
final columns =
    constraints.maxWidth >= kWideBreakpoint ? 2 : 1;
```

Artinya:

- Jika lebar layar kurang dari `700.0`, digunakan **1 kolom**.
- Jika lebar layar `700.0` atau lebih, digunakan **2 kolom**.

Dengan cara ini, tampilan dashboard dapat menyesuaikan ukuran layar.

### Tampilan Narrow

Pada layar sempit, susunan card menjadi:

```text
Assignments

Attendance

Portfolio

Current week
```

### Tampilan Wide

Pada layar lebar, susunan card menjadi:

```text
Assignments     Attendance

Portfolio       Current week
```

---

## 4. Light dan Dark Mode

Aplikasi memiliki dua theme, yaitu light mode dan dark mode.

Toggle theme diletakkan pada bagian AppBar menggunakan `CupertinoSwitch`.

State untuk menyimpan kondisi theme dibuat dengan:

```dart
bool isDark = false;
```

Kemudian theme ditentukan berdasarkan nilai tersebut:

```dart
themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
```

Jika `isDark` bernilai `false`, aplikasi menggunakan light mode.

Jika `isDark` bernilai `true`, aplikasi menggunakan dark mode.

---

## 5. Accessibility

Untuk membantu accessibility, beberapa bagian penting pada aplikasi diberikan `Semantics`.

Pada information card digunakan:

```dart
Semantics(
  label: '$title: $value',
  child: Card(
    ...
  ),
)
```

Sehingga informasi pada card dapat dibaca dengan lebih jelas oleh screen reader.

Toggle dark mode juga diberikan label:

```dart
Semantics(
  label: 'Toggle dark mode',
  child: CupertinoSwitch(
    ...
  ),
)
```

---

# Struktur Project

Struktur utama folder Week 2 adalah:

```text
02-week-2-declarative-ui-responsive-design/
│
├── README.md
├── lib/
│   └── main.dart
│
├── test/
│   └── widget_test.dart
│
└── screenshots/
    ├── narrow.png
    └── wide.png
```

File utama yang digunakan adalah:

- `lib/main.dart` → kode aplikasi
- `test/widget_test.dart` → widget test
- `screenshots/narrow.png` → hasil tampilan layar sempit
- `screenshots/wide.png` → hasil tampilan layar lebar
- `README.md` → dokumentasi project

---

# Widget yang Digunakan

Beberapa widget Flutter yang digunakan dalam project ini antara lain:

| Widget | Kegunaan |
|---|---|
| `MaterialApp` | Menjadi root dari aplikasi dan mengatur theme |
| `Scaffold` | Menyusun struktur halaman |
| `AppBar` | Menampilkan judul dan toggle theme |
| `LayoutBuilder` | Menyesuaikan layout berdasarkan ukuran layar |
| `Column` | Menyusun widget secara vertikal |
| `Row` | Menyusun widget secara horizontal |
| `Expanded` | Mengatur penggunaan ruang yang tersedia |
| `Container` | Membuat bagian profile header |
| `GridView.count` | Menampilkan card dalam bentuk grid |
| `Card` | Membuat tampilan card |
| `CircleAvatar` | Menampilkan icon profile |
| `CupertinoSwitch` | Mengubah light/dark mode |
| `Semantics` | Menambahkan informasi accessibility |

---

# AI Prompt Challenge

Pada tugas ini juga dilakukan beberapa percobaan menggunakan AI untuk membantu memahami keputusan teknis yang digunakan pada project.

## 1. GridView vs LayoutBuilder + Column

### Prompt

> Compare GridView and LayoutBuilder + Column for creating a responsive dashboard in Flutter. Explain the trade-offs in terms of responsive layout, flexibility, scrolling, and accessibility. Recommend the most appropriate approach for this Academic Overview dashboard.

### Hasil Utama

Dari perbandingan tersebut, `GridView` cocok digunakan untuk menampilkan beberapa item dalam bentuk grid dan juga sudah mendukung scrolling.

Sementara itu, `LayoutBuilder` dapat digunakan untuk mengetahui ukuran area yang tersedia sehingga layout dapat dibuat menyesuaikan ukuran layar.

Pada project ini, keduanya digunakan bersama.

Struktur akhirnya adalah:

```text
LayoutBuilder
      ↓
Column
      ↓
ProfileHeader
      ↓
Expanded
      ↓
GridView.count
```

### Keputusan

Pendekatan tersebut dipilih karena sesuai dengan kebutuhan dashboard.

Profile header dibuat terpisah, sedangkan card diletakkan di dalam `GridView`.

Dengan begitu, pada layar sempit profile tetap memiliki ruang yang cukup dan card dapat ditampilkan satu per satu.

---

## 2. Masalah Expanded dan Overflow

### Prompt

> Explain when Expanded causes overflow in Row or Column in Flutter. Show an example of failed code and explain how to fix it.

### Hasil Utama

`Expanded` digunakan ketika sebuah widget ingin mengisi ruang yang tersedia di dalam `Row` atau `Column`.

Namun, penggunaan `Expanded` tetap harus memperhatikan constraint dari parent.

Dalam proses pengerjaan dashboard, sempat terjadi overflow pada bagian profile ketika profile header masih ditempatkan di dalam area grid.

Masalah tersebut terjadi karena ruang yang tersedia untuk profile menjadi terlalu terbatas pada layar sempit.

### Perbaikan

Profile header kemudian dipisahkan dari `GridView`.

Struktur akhirnya menjadi:

```text
Column
├── ProfileHeader
└── Expanded
    └── GridView
```

Dengan struktur tersebut, profile header mendapatkan ruangnya sendiri dan `GridView` menggunakan sisa ruang yang tersedia.

---

## 3. Verification

### Prompt

> Verify whether the responsive layout, accessibility implementation, and Flutter widgets used in the dashboard are appropriate and stable.

### Hasil Verification

Responsive layout diuji menggunakan dua ukuran layar:

```text
400 x 800
```

dan:

```text
1200 x 800
```

Hasil yang diharapkan:

```text
400 x 800  → 1 column
1200 x 800 → 2 columns
```

Accessibility diterapkan menggunakan `Semantics` pada information card dan toggle dark mode.

Widget yang digunakan juga merupakan widget Flutter yang digunakan secara langsung dalam project, seperti:

- `LayoutBuilder`
- `Column`
- `Row`
- `Expanded`
- `GridView`
- `Card`
- `CupertinoSwitch`
- `Semantics`

---

# Refactoring

Setelah fitur utama selesai, dilakukan beberapa perubahan pada kode agar lebih rapi dan mudah digunakan kembali.

## 1. Membuat InfoCard sebagai Reusable Widget

Information card dibuat menjadi widget tersendiri:

```dart
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    super.key,
  });

  final String title;
  final String value;
}
```

Dengan begitu, tidak perlu membuat struktur card yang sama berulang kali.

---

## 2. Menggunakan Theme

Untuk beberapa bagian tampilan digunakan `Theme.of(context)`.

Contohnya:

```dart
Theme.of(context).textTheme.titleLarge
```

dan:

```dart
Theme.of(context).colorScheme.surfaceContainerHighest
```

Penggunaan theme membuat tampilan dapat mengikuti light dan dark mode.

---

## 3. Membuat Breakpoint sebagai Constant

Breakpoint responsive dibuat menjadi satu constant:

```dart
const kWideBreakpoint = 700.0;
```

Constant ini digunakan oleh `LayoutBuilder` sehingga nilai breakpoint tidak ditulis berulang kali.

---

# Testing

Widget test dibuat untuk mengecek apakah dashboard dapat menyesuaikan layout pada ukuran layar yang berbeda.

## 1. Narrow Screen

Ukuran layar yang digunakan:

```text
400 x 800
```

Test mengecek bahwa ukuran card berada pada kondisi layar sempit.

```dart
expect(width.width, lessThan(700));
```

Hasil yang diharapkan adalah dashboard menggunakan satu kolom.

---

## 2. Wide Screen

Ukuran layar yang digunakan:

```text
1200 x 800
```

Test mengecek ukuran card pada kondisi layar lebar.

```dart
expect(width.width, greaterThan(500));
```

Hasil yang diharapkan adalah dashboard menggunakan dua kolom.

---

## Menjalankan Widget Test

Untuk menjalankan test digunakan perintah:

```bash
flutter test
```

Hasil pengujian:

```text
00:01 +2: All tests passed!
```

Artinya kedua widget test berhasil dijalankan.

---

# Flutter Analyze

Selain widget test, project juga diperiksa menggunakan `flutter analyze`.

Perintah yang digunakan:

```bash
flutter analyze
```

Hasil:

```text
Analyzing 02-week-2-declarative-ui-responsive-design...
No issues found! (ran in 1.1s)
```

Hasil tersebut menunjukkan bahwa pada saat dilakukan pengecekan tidak ditemukan masalah dari static analysis Flutter.

---

# Hasil dan Output Aplikasi

Setelah aplikasi dijalankan, halaman utama menampilkan **Academic Overview**.

Tampilan terdiri dari profile mahasiswa dan empat information card.

Secara umum tampilannya adalah:

```text
Academic Overview

[ Profile ]
Vanesa Mardiana Putri
244107020129 • TI-3G

[ Assignments ]    8
[ Attendance ]     92%
[ Portfolio ]      Ready
[ Current week ]   02
```

Pada bagian kanan AppBar terdapat toggle yang dapat digunakan untuk mengubah light mode dan dark mode.

---

## Hasil Narrow Layout

Pada ukuran layar sempit, dashboard menggunakan satu kolom.

```text
400 x 800

Profile Header

Assignments
Attendance
Portfolio
Current week
```

Screenshot hasil running:

![Narrow Layout](screenshots/narrow.png)

---

## Hasil Wide Layout

Pada ukuran layar lebar, dashboard menggunakan dua kolom.

```text
1200 x 800

Profile Header

Assignments     Attendance

Portfolio       Current week
```

Screenshot hasil running:

![Wide Layout](screenshots/wide.png)

---

# Hasil Light dan Dark Mode

Aplikasi dapat berpindah dari light mode ke dark mode menggunakan `CupertinoSwitch`.

Kondisi awal:

```text
Light Mode
```

Setelah toggle diaktifkan:

```text
Dark Mode
```

Perubahan tersebut dilakukan menggunakan:

```dart
themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
```

---

# Cara Menjalankan Project

## 1. Masuk ke Folder Project

Buka terminal kemudian masuk ke folder Week 2:

```bash
cd 02-week-2-declarative-ui-responsive-design
```

---

## 2. Menjalankan Aplikasi

Untuk menjalankan aplikasi pada device yang tersedia:

```bash
flutter run
```

Jika ingin menjalankan pada Android Emulator yang digunakan saat pengerjaan:

```bash
flutter run -d emulator-5554
```

---

## 3. Menjalankan Test

Untuk menjalankan widget test:

```bash
flutter test
```

---

## 4. Menjalankan Flutter Analyze

Untuk mengecek apakah terdapat masalah pada project:

```bash
flutter analyze
```

---

# Kesimpulan

Pada tugas Week 2 ini, dashboard Flutter dikembangkan menjadi **Academic Overview Dashboard** yang dapat menyesuaikan tampilannya berdasarkan ukuran layar.

Beberapa konsep yang berhasil diterapkan adalah:

- `Row`
- `Column`
- `Expanded`
- `Container`
- `LayoutBuilder`
- `GridView`
- Reusable widget
- Light/dark mode
- `CupertinoSwitch`
- `Semantics`
- Widget testing

Responsive layout dibuat dengan breakpoint `700.0`. Pada layar sempit dashboard menggunakan satu kolom, sedangkan pada layar lebar menggunakan dua kolom.

Selain itu, dilakukan refactoring dengan membuat `InfoCard` sebagai reusable widget dan menggunakan `Theme.of(context)` untuk beberapa bagian tampilan.

Pengujian dilakukan menggunakan `flutter test` dan `flutter analyze`. Hasil widget test menunjukkan bahwa kedua test berhasil dijalankan, sedangkan `flutter analyze` tidak menemukan masalah pada saat pengecekan.

Screenshot hasil running aplikasi disimpan pada folder `screenshots/` sebagai dokumentasi hasil implementasi.