# Aturan Conflict Resolution - Offline-First Notes

## Strategi: Last-Write-Wins (LWW)

Ketika terjadi konflik data antara versi lokal dan server, sistem menggunakan **Last-Write-Wins** berdasarkan field `updated_at`.

### Logika Default

```
if (local.updated_at >= server.updated_at) {
  // gunakan local (tidak perlu sync ke server)
} else {
  // gunakan server (perbarui local)
}
```

### Kapan Konflik Terjadi

1. **User mengedit catatan lokal** saat aplikasi offline
2. **Seseorang di device lain mengedit catatan yang sama** pada waktu yang sama
3. **Sync terjadi** → dibandingkan `updated_at` dari kedua versi

### Implementasi di Praktikum Ini

Saat ini project menggunakan **simulasi backend**, jadi aturan LWW belum sepenuhnya diuji terhadap server nyata. Namun, mekanisme yang disiapkan sudah mendukung:

- Field `updated_at` di setiap catatan utk urutan yang jelas
- Flag `dirty` untuk menandai catatan yang belum sync
- Fungsi `syncNotes()` yang akan mengirim catatan kotor ke server (nantinya)
- Fungsi `markAllSynced()` untuk menandai catatan sudah tersinkronkan

### Langkah Testing Manual

1. **Offline Mode aktif** → edit catatan (bertanda `dirty`)
2. **Matikan offline mode** → jalankan sync
3. **Cek hasil**: catatan seharusnya sudah `dirty = 0`

### Catatan Penting

- **Tidak boleh overwrite diam-diam**: setiap sync harus mempertimbangkan `updated_at`
- **Jika production**: tambahkan versioning atau CRDTs jika konflik sering terjadi
- **Saat ini**: LWW cukup untuk demo offline-first patterns

---

## Referensi

- Tabel `notes`: kolom `updated_at` menyimpan ISO 8601 timestamp
- Repository: `lib/data/repositories/note_repository.dart`
- Service: `lib/data/sync_service.dart`
- Halaman: `lib/pages/notes_page.dart` (tampilkan dirty badge)
