# Week 13 – CI/CD Automation

Nama : Vanesa Mardiana Putri
NIM : 244107020129
Kelas : TI-3G
Absen : 25

## 1. Ringkasan

Praktikum Week 13 menambahkan pipeline **Continuous Integration (CI)** dan **Continuous Delivery (CD)** pada aplikasi **Notes App** dari project Week 10 (`10-week-10-ai-feature-integration`). Sama seperti Week 12, folder Week 13 ini menjadi tempat dokumentasi dan bukti, sedangkan kode aplikasi serta test tetap satu sumber di project Week 10.

Workflow GitHub Actions diletakkan di **root repository** karena GitHub hanya membaca file dari `.github/workflows/` pada root repo, bukan dari subfolder minggu. Karena project Flutter berada di subfolder, setiap step memakai `working-directory`:

```yaml
defaults:
  run:
    working-directory: 10-week-10-ai-feature-integration
```

## 2. Alur pipeline

1. `push` ke `main`, `pull_request` ke `main`, atau `workflow_dispatch` memicu workflow.
2. Runner `ubuntu-latest` mengambil source code (`actions/checkout@v4`).
3. `subosito/flutter-action@v2` memasang Flutter stable dan cache.
4. Pemeriksaan dijalankan berurutan: `flutter pub get`, format, analisis statis, dan test dengan coverage.
5. Jika semua lulus, APK dan AAB release dibangun.
6. Keduanya diunggah sebagai artefak `android-builds` (retensi 7 hari).

## 3. File workflow

`.github/workflows/flutter-ci.yml` (root repo):

```yaml
name: Flutter CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test-and-build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 10-week-10-ai-feature-integration
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.44.5
          cache: true
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - run: flutter build apk --release
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: android-builds
          path: |
            10-week-10-ai-feature-integration/build/app/outputs/flutter-apk/app-release.apk
            10-week-10-ai-feature-integration/build/app/outputs/bundle/release/app-release.aab
          if-no-files-found: error
          retention-days: 7
```

Catatan permission: workflow hanya butuh `contents: read` karena tidak menulis ke repository, tidak membuat release, dan tidak mengunggah ke Play Store.

## 4. Pemeriksaan yang dijalankan

| Tahap | Perintah | Tujuan |
|---|---|---|
| Dependensi | `flutter pub get` | Mengambil dependency dari `pubspec.yaml` |
| Format | `dart format --output=none --set-exit-if-changed .` | Gagal jika ada file tidak terformat |
| Analisis statis | `flutter analyze --fatal-infos` | Gagal pada error, warning, dan info |
| Test | `flutter test --coverage` | Menjalankan 48 unit/widget test + menghasilkan `coverage/lcov.info` |
| Build APK | `flutter build apk --release` | Artefak instalasi/uji internal |
| Build AAB | `flutter build appbundle --release` | Artefak distribusi Google Play |
| Artefak | `actions/upload-artifact@v4` | Menyimpan APK dan AAB selama 7 hari |

### Hasil verifikasi lokal sebelum push

```bash
$ dart format .
Formatted 27 files (9 changed) in 0.11 seconds.

$ flutter analyze --fatal-infos
Analyzing 10-week-10-ai-feature-integration...
No issues found! (ran in 1.6s)

$ flutter test --coverage
00:02 +48: All tests passed!
```

Integration test tidak dijalankan di CI karena membutuhkan emulator/perangkat Android. Integration test tetap dijalankan manual seperti pada laporan Week 12.

### Catatan toolchain

Run pertama di GitHub Actions memakai Flutter stable terbaru saat itu (**3.50.1**) dan gagal pada `flutter analyze --fatal-infos` karena `package:flutter/material.dart` sudah deprecated (diganti `package:material_ui/material_ui.dart` setelah v3.47). Project ini dikembangkan dan diuji dengan **Flutter 3.44.5 / Dart 3.12.2** (revision `f94f4fc`), sehingga workflow dipin ke versi tersebut:

```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: 3.44.5
    cache: true
```

Pinning membuat CI konsisten dengan toolchain pengembangan dan mencegah perubahan upstream tiba-tiba. Migrasi ke Flutter 3.50+ dan `material_ui` dicatat sebagai pekerjaan lanjutan, bukan dengan mematikan pemeriksaan.

### Bukti run CI (GitHub Actions)

| Item | Nilai |
|---|---|
| Workflow | `Flutter CI` |
| Run ID | `44975452199` |
| URL | https://github.com/vanesamrd/244107020129-mobile-course/actions/runs/44975452199 |
| Commit | `ae3adfa` (`ci(week-13): pin flutter 3.44.5 to match project toolchain`) |
| Event | `push` ke `main` |
| Toolchain | Flutter 3.44.5 |
| Durasi | 02:18:16–02:24:12 UTC (±5 menit 56 detik) |
| Hasil | **success** |

Seluruh step berhasil:

| # | Step | Hasil |
|---:|---|---|
| 1 | Set up job | success |
| 2 | `actions/checkout@v4` | success |
| 3 | `subosito/flutter-action@v2` | success |
| 4 | `flutter pub get` | success |
| 5 | `dart format --output=none --set-exit-if-changed .` | success |
| 6 | `flutter analyze --fatal-infos` | success |
| 7 | `flutter test --coverage` | success |
| 8 | `flutter build apk --release` | success |
| 9 | `flutter build appbundle --release` | success |
| 10 | `actions/upload-artifact@v4` | success |

Artefak **`android-builds`** tersedia (74.420.196 byte / ±74,4 MB, belum kedaluwarsa, retensi 7 hari) dan dapat diunduh dari halaman run.

### Screenshot bukti

- `screenshots/ci-run-44975452199.png` – ringkasan run sukses: commit `ae3adfa`, status **Success**, durasi, dan artefak `android-builds`.
- `screenshots/ci-job-steps-44975452199.png` – seluruh step job `test-and-build` berstatus hijau.
- `screenshots/commit-ae3adfa.png` – halaman commit `ae3adfa` pada GitHub.

## 5. Cara menjalankan dan mengambil artefak

1. Commit dan push workflow ke GitHub.
2. Buka tab **Actions** pada repository.
3. Pilih run **Flutter CI** yang sesuai (commit atau pull request).
4. Tinjau setiap step; kegagalan format, analyze, atau test akan membuat job gagal.
5. Unduh artefak **android-builds** dari halaman run dan catat commit yang menghasilkannya.

## 6. Versi dan tag

- Versi saat ini: `1.0.0+1` (`pubspec.yaml`).
- Versi berikutnya yang direncanakan: **`1.0.1+2`**.
  - `1.0.1` = patch, karena Week 12–13 hanya menambah test, dokumentasi, dan pipeline tanpa perubahan fitur yang terlihat pengguna.
  - `+2` = build number dinaikkan satu untuk setiap unggahan baru.
- Tag yang disarankan: `v1.0.1`, dibuat **setelah** commit lolos pemeriksaan CI, sehingga source, log pipeline, dan artefak dapat ditelusuri ke commit yang sama.

## 7. Risiko keamanan yang masih perlu ditangani

1. **Release masih ditandatangani debug key.** `android/app/build.gradle.kts` memakai `signingConfigs.getByName("debug")` untuk release. Build sukses, tetapi belum layak dipublikasikan. Perlu keystore produksi melalui GitHub Actions Secrets pada workflow rilis terbatas.
2. **Belum ada unggahan ke Play Store.** Workflow hanya menyimpan artefak; publikasi, signing, dan review Play Console masih manual.
3. **Secret belum digunakan.** API key Gemini diisi pengguna dan disimpan di `flutter_secure_storage`, bukan di repository. Jika nanti ada token build, simpan di GitHub Actions Secrets dan jangan mencetaknya ke log.
4. **`--dart-define` bukan tempat rahasia.** Nilai yang dimasukkan lewat `--dart-define` dapat diekstrak dari aplikasi klien.
5. **Action memakai tag, bukan commit SHA.** Untuk rantai pasok yang lebih ketat, pin `actions/checkout`, `subosito/flutter-action`, dan `actions/upload-artifact` ke commit SHA.
6. **Belum ada pengujian perangkat nyata.** Build sukses tidak menjamin izin, konfigurasi aplikasi, dan perilaku di perangkat sudah benar.
7. **Integration test tidak berjalan di CI.** Perlu emulator (misalnya `reactivecircus/android-emulator-runner`) jika ingin diotomatiskan.
8. **SDK dipin ke Flutter 3.44.5.** Perlu pekerjaan lanjutan untuk upgrade ke Flutter 3.50+ dan migrasi import `package:flutter/material.dart` menjadi `package:material_ui/material_ui.dart`.
9. **`pubspec.lock` belum di-commit.** Root `.gitignore` mengabaikan `pubspec.lock`, sehingga dependency di CI dapat ter-resolve berbeda dari lokal. Untuk aplikasi, sebaiknya `pubspec.lock` di-commit agar build reproducible.

## 8. Jawaban pertanyaan refleksi

**Masalah apa yang ditemukan otomatis sebelum perubahan di-merge?**
File yang tidak sesuai format Dart, error/warning/info dari `flutter analyze`, dan test yang gagal. Pipeline juga otomatis memastikan project masih dapat di-build menjadi APK dan AAB, sehingga broken build terdeteksi sebelum merge.

**Informasi apa yang Anda butuhkan untuk menyelidiki build yang gagal?**
Nama workflow dan nomor run, commit SHA dan branch/PR, step yang gagal beserta log lengkap, versi Flutter/Dart, isi `pubspec.yaml`/`pubspec.lock`, serta artefak atau output test bila tersedia. Dengan `concurrency`, pastikan juga run yang diperiksa bukan run yang dibatalkan.

**Bagian mana yang masih perlu persetujuan atau pemeriksaan manual sebelum rilis?**
Signing dan keystore produksi, konfigurasi `applicationId`/versi, izin Android, penanganan API key, pengujian di perangkat nyata, peninjauan perubahan UI, serta unggahan dan review di Google Play Console.

## 9. File yang dibuat

- `.github/workflows/flutter-ci.yml` (root repo) – pipeline CI/CD.
- `13-week-13-ci-cd-automation/README.md` – dokumentasi ini.
- `13-week-13-ci-cd-automation/screenshots/` – tempat bukti screenshot run Actions dan artefak.

Folder `13-week-13-ci-cd-automation/.github/` dan `workflows/` hanya scaffold dari template; workflow yang benar-benar dijalankan berada di root repo.
