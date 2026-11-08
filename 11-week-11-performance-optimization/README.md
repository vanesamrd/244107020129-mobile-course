# Week 11 — Performance Optimization

Project Flutter Notes App yang merupakan salinan mandiri dari Week 10 (AI Feature Integration). Fokus Week 11 adalah optimasi performa pencarian, rebuild widget dengan Riverpod, dan operasi CRUD lokal.

## Dokumentasi

- [`docs/performance-findings.md`](docs/performance-findings.md) — analisis masalah performa sebelum optimasi.
- [`docs/performance-implementation.md`](docs/performance-implementation.md) — perubahan kode dan cara menguji optimasi.
- [`docs/performance-report.md`](docs/performance-report.md) — laporan performa, baseline, keterbatasan data, dan checklist pengukuran after.

## Menjalankan project

```bash
flutter pub get
flutter run
```

## Verifikasi

```bash
flutter analyze
flutter test
flutter build macos --debug
```

Status terakhir: `flutter analyze` tanpa issue, 40 test lulus, dan build macOS debug berhasil.

## Catatan profiling

Baseline: 418 frame, 110 frame janky, jank rate 26,3% pada 60 Hz. Enam screenshot profiling tersedia di `screenshots/`, tetapi belum ada export DevTools Performance (`.json`) atau CSV memory; metrik after belum dapat dihitung dan peningkatan performa belum dapat diklaim. Lihat `docs/performance-report.md` untuk detail dan cara melengkapi data.
