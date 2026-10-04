# AI Challenge – Campus Notify

## 1. Peran AI pada Codelab

Pada codelab ini, AI digunakan sebagai **coding assistant** untuk membantu membuat draf awal service Firebase Cloud Messaging (FCM) dan boilerplate autentikasi. AI membantu mempercepat proses penulisan kode, tetapi hasil dari AI tidak langsung diterima begitu saja. Setiap bagian kode tetap diperiksa dan diuji untuk memastikan perilakunya sesuai dengan kebutuhan aplikasi.

Hal yang menjadi perhatian utama adalah lifecycle token FCM, notifikasi ketika aplikasi berada pada kondisi foreground, background, dan terminated, serta navigasi ketika pengguna menekan notifikasi. Dengan demikian, penggunaan AI tidak hanya menghasilkan kode, tetapi juga harus dibuktikan melalui pengujian pada aplikasi.

---

## 2. AI Prompt Challenge

Prompt berikut digunakan pada AI coding assistant untuk membuat draf awal `PushService`:

```text
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

### Screenshot Prompt

![AI Prompt](screenshots/ai-prompt.png)

---

## 3. Output Awal AI

AI menghasilkan draf awal kode berdasarkan prompt yang diberikan. Output tersebut kemudian digunakan sebagai bahan awal implementasi, bukan sebagai hasil akhir yang langsung digunakan.

### Screenshot Output AI

![AI Output](screenshots/ai-output.png)

---

## 4. Verifikasi Output AI

Setelah mendapatkan output dari AI, kode diperiksa menggunakan beberapa poin verifikasi berikut.

| No | Bagian yang Diverifikasi                                 | Hasil      | Keterangan                                                                                                           |
| -- | -------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------- |
| 1  | Background handler berupa fungsi top-level               | Sesuai     | Background handler dibuat di luar class dan menggunakan `@pragma('vm:entry-point')`.                                 |
| 2  | `onTokenRefresh` mengirim token baru ke backend          | Sesuai     | Token baru dikirim ke endpoint `/devices`, bukan hanya ditampilkan pada log.                                         |
| 3  | Foreground menggunakan local notification                | Sesuai     | `onMessage` digunakan untuk menerima pesan ketika aplikasi terbuka dan menampilkan local notification secara manual. |
| 4  | `onMessageOpenedApp` menangani klik notifikasi           | Sesuai     | Data `route` digunakan untuk menentukan halaman tujuan ketika notifikasi dibuka.                                     |
| 5  | `getInitialMessage` menangani kondisi terminated         | Sesuai     | Pesan awal diperiksa ketika aplikasi dibuka melalui notifikasi saat sebelumnya tidak berjalan.                       |
| 6  | Token/secret tidak di-hardcode                           | Sesuai     | Token tidak ditulis secara langsung di source code.                                                                  |
| 7  | Token tidak di-log secara penuh                          | Diperbaiki | Logging token sensitif dihindari agar token tidak tersebar melalui console log.                                      |
| 8  | Tidak menggunakan `BuildContext` pada background handler | Sesuai     | Background handler tidak bergantung pada `BuildContext`.                                                             |

---

## 5. Perbaikan Manual

Walaupun AI dapat menghasilkan kode awal dengan cepat, beberapa bagian tetap perlu diperiksa dan disesuaikan secara manual.

Perbaikan pertama berkaitan dengan keamanan token. Token dan informasi sensitif tidak boleh di-hardcode atau ditampilkan secara penuh pada log karena dapat menyebabkan informasi autentikasi terekspos. Penyimpanan token yang sensitif menggunakan `flutter_secure_storage` agar lebih aman dibandingkan penyimpanan biasa.

Perbaikan berikutnya berkaitan dengan lifecycle FCM. `onTokenRefresh` harus benar-benar mengirim token terbaru ke backend karena token FCM dapat berubah. Jika token baru tidak dikirim ke backend, server dapat menggunakan token lama sehingga perangkat tidak lagi menerima notifikasi.

Pada bagian background handler, fungsi harus berada pada level top-level dan menggunakan `@pragma('vm:entry-point')`. Background handler juga tidak boleh bergantung pada `BuildContext` karena proses tersebut berjalan di luar lifecycle UI normal.

Untuk foreground, notifikasi perlu ditampilkan menggunakan `flutter_local_notifications` secara manual. Hal ini diperlukan karena ketika aplikasi sedang terbuka, pesan FCM tidak selalu ditampilkan sebagai banner sistem secara otomatis.

---

## 6. Pengujian Tiga App State

Pengujian dilakukan untuk memastikan notifikasi dan navigasi berjalan pada tiga kondisi aplikasi, yaitu **foreground, background, dan terminated**.

| No | App State  | Skenario Pengujian                                                 | Hasil yang Diharapkan                                        | Hasil Pengujian |
| -- | ---------- | ------------------------------------------------------------------ | ------------------------------------------------------------ | --------------- |
| 1  | Foreground | Aplikasi sedang terbuka kemudian menerima notifikasi               | Local notification muncul dan data notifikasi dapat diproses | Berhasil        |
| 2  | Background | Aplikasi berada di background kemudian pengguna menekan notifikasi | Aplikasi terbuka dan diarahkan ke route pada `data.route`    | Berhasil        |
| 3  | Terminated | Aplikasi ditutup, kemudian pengguna menekan notifikasi             | Aplikasi dibuka dan diarahkan ke route pada `data.route`     | Berhasil        |

### Contoh Route

Payload FCM yang digunakan untuk pengujian:

```json
{
  "notification": {
    "title": "Pengumuman Kampus",
    "body": "Jadwal kuliah mengalami perubahan."
  },
  "data": {
    "route": "/pengumuman/3",
    "id": "3"
  }
}
```

Berdasarkan pengujian tersebut, route dari data notifikasi digunakan sebagai tujuan navigasi. Dengan demikian, pengguna tidak hanya menerima notifikasi, tetapi juga dapat langsung diarahkan ke halaman pengumuman yang sesuai.

---

## 7. Perbedaan Android 13+ dan iOS

### Android 13+

Pada Android 13 dan versi yang lebih baru, aplikasi perlu meminta izin `POST_NOTIFICATIONS` sebelum dapat menampilkan notifikasi kepada pengguna. Oleh karena itu, permission notification perlu diperhatikan pada proses setup FCM dan local notification.

### iOS

Pada iOS, aplikasi juga harus meminta izin notifikasi kepada pengguna. Selain itu, konfigurasi Firebase dan APNs diperlukan agar Firebase Cloud Messaging dapat bekerja dengan baik pada perangkat iOS.

Implementasi juga harus memperhatikan perbedaan konfigurasi platform sehingga permission dan notification channel tidak dianggap sama antara Android dan iOS.

---

## 8. Bagian yang Tidak Boleh Mengakses BuildContext

`BuildContext` tidak digunakan pada background handler FCM. Background handler dapat berjalan ketika aplikasi berada di background dan tidak boleh bergantung pada widget tree atau context dari halaman tertentu.

Untuk navigasi dari notifikasi, data seperti `data.route` digunakan untuk menentukan tujuan navigasi melalui sistem routing aplikasi. Dengan cara ini, proses FCM tetap terpisah dari UI dan lebih aman terhadap masalah lifecycle `BuildContext`.

---

## 9. Keputusan Final

Draf dari AI **diterima sebagai dasar implementasi**, tetapi tidak langsung digunakan tanpa pemeriksaan. Bagian yang berhubungan dengan lifecycle token, keamanan token, background handler, foreground notification, dan navigasi tetap diverifikasi secara manual.

Perbaikan manual dilakukan terutama untuk memastikan token baru dari `onTokenRefresh` benar-benar dikirim ke backend, token sensitif tidak ditampilkan secara penuh pada log, dan background handler tidak menggunakan `BuildContext`. Pengujian pada foreground, background, dan terminated juga dilakukan untuk memastikan klik notifikasi masuk ke route yang benar.

Dari proses ini dapat disimpulkan bahwa AI membantu mempercepat pembuatan kode, tetapi keputusan akhir tetap berada pada developer. Kode yang dihasilkan AI harus dipahami, diperiksa, diperbaiki, dan dibuktikan melalui pengujian sebelum digunakan pada aplikasi.

---

## 10. Kesimpulan

AI sangat membantu dalam membuat boilerplate dan memberikan gambaran awal implementasi FCM. Namun, output AI tidak dapat langsung dianggap benar karena masalah seperti token basi, notifikasi ganda, dan navigasi yang salah dapat terjadi pada kondisi tertentu.

Melalui AI Challenge ini, implementasi diuji berdasarkan lifecycle aplikasi dan lifecycle token FCM. Hasil pengujian menunjukkan bahwa aplikasi dapat menangani notifikasi pada foreground, background, dan terminated serta mengarahkan pengguna berdasarkan `data.route`.

Dokumentasi ini juga menunjukkan bahwa penggunaan AI dalam pengembangan aplikasi tetap membutuhkan verifikasi dan tanggung jawab teknis dari developer.
