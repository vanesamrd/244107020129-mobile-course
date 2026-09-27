# Screenshots & Observasi - Praktikum 3: Offline-First Patterns

## Petunjuk Pengisian

1. **Ambil screenshot sebelum dan sesudah** setiap skenario di bawah
2. **Simpan file gambar** di folder ini dengan naming yang jelas
3. **Catat observasi** dalam format markdown di bawah

---

## Skenario 1: Catatan Tetap Tampil Offline

### Langkah
1. Buat 1-2 catatan baru (otomatis mendapat `dirty = 1`)
2. Aktifkan toggle **"Offline"** di AppBar halaman notes
3. Amati badge jumlah catatan belum sync
4. Tutup aplikasi dan buka kembali
5. Verifikasi catatan masih ada dan jumlah dirty akurat

### Screenshot
- **Sebelum offline**: `01_before_offline.png`
- **Sesudah offline + reopen**: `02_after_offline_reopen.png`

### Observasi
```
Status: [ ] Belum diambil
Catatan yang dibuat: _____ buah
Badge dirty sebelum offline: _____ 
Badge dirty setelah reopen: _____
Catatan hilang?: Ya/Tidak
Catatan tetap akurat?: Ya/Tidak
```

---

## Skenario 2: Sync Menghilangkan Dirty Flag

### Langkah
1. Pastikan ada catatan dengan status "belum sync" (badge > 0)
2. **Matikan toggle offline** (jika aktif)
3. Tekan tombol **Sync** (icon ⟳)
4. Tunggu snackbar menampilkan hasil sync
5. Lihat badge kembali ke 0

### Screenshot
- **Sebelum sync**: `03_before_sync.png`
- **Sesudah sync**: `04_after_sync.png`

### Observasi
```
Status: [ ] Belum diambil
Jumlah catatan dirty sebelum sync: _____ 
Snackbar hasil: "_____________________"
Badge setelah sync: _____ 
Pesan "0 belum sync" muncul?: Ya/Tidak
```

---

## Skenario 3: Offline Mode Deterministik (Opsional)

### Langkah
1. Aktifkan offline toggle (simulasi mode pesawat)
2. Tekan tombol sync
3. Amati pesan error atau snackbar
4. Matikan toggle offline
5. Sync kembali berhasil

### Screenshot
- **Sync saat offline**: `05_sync_offline_error.png`
- **Sync setelah online**: `06_sync_online_success.png`

### Observasi
```
Status: [ ] Belum diambil
Pesan error saat sync offline: "_____________________"
Pesan sukses setelah online: "_____________________"
Toggle offline berfungsi dengan baik?: Ya/Tidak
```

---

## Catatan Teknis

- Semua data catatan tersimpan di SQLite lokal (`offline_notes.db`)
- Flag `dirty = 1` menandai catatan belum tersinkronkan
- Offline toggle adalah **simulasi**, bukan mode pesawat nyata
- Database tetap berfungsi di mode offline karena data lokal

---

## Rangkuman Nilai Praktikum

| Komponen | Status | Catatan |
|----------|--------|---------|
| SharedPreferences | ✓ | Dark mode + last opened |
| SQLite + Repository | ✓ | CRUD dengan dirty tracking |
| Cache-first API | ✓ | `loadPostsCacheFirst()` siap |
| Sync Deterministic | ✓ | `forceOfflineProvider` aktif |
| Conflict Resolution | ✓ | LWW via `updated_at` |
| Demo Offline | Pending | Tunggu screenshot skenario |

