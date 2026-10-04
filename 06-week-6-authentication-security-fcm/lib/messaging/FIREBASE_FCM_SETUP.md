# 🔥 Firebase FCM Setup & Testing Guide

## 📋 Quick Setup Checklist

Ini adalah panduan **step-by-step** untuk setup Firebase FCM di Campus Notification App.

---

## 1️⃣ Setup Firebase Project (Cloud Console)

### Step 1: Buka Firebase Console
```
https://console.firebase.google.com/
```

### Step 2: Pilih Atau Buat Project
1. Klik "Select a project" atau buat project baru
2. Beri nama: **campus_notify** (atau sesuaikan)
3. Pilih region: **Asia Southeast 1 (Jakarta)** (opsional, untuk latency rendah)
4. Klik "Create project"

### Step 3: Tunggu Inisialisasi
Firebase akan setup project infrastructure. Tunggu sampai selesai (~5 menit).

---

## 2️⃣ Setup Android FCM

### A. Download `google-services.json`

**Step 1: Daftar App Android**
```
Firebase Console → Project Settings (⚙️) → Your Apps
```

1. Klik **"Add App"** → Pilih **Android**
2. Isi Android Package Name: 
   ```
   com.example.campus_notify
   ```
   (Atau sesuaikan dengan package di `android/app/build.gradle`)

3. Isi App Nickname: `Campus Notify Android`

4. Klik **"Register app"**

**Step 2: Download Configuration File**
```
Klik "Download google-services.json"
```

**Step 3: Tempat yang Benar**
```
android/app/google-services.json  ← Simpan di sini
```

### B. Setup Android Gradle

**File: `android/app/build.gradle.kts`**

Pastikan sudah ada:
```kotlin
plugins {
    id "com.google.gms.google-services"  // ← Ini harus ada
}

dependencies {
    // Firebase sudah multi-method indexed ke build
}
```

**File: `android/build.gradle.kts`** (Root)

Cek sudah ada dependency Firebase Maven:
```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        // Firebase dependencies auto-resolved
    }
}
```

### C. Verifikasi AndroidManifest.xml

**File: `android/app/src/main/AndroidManifest.xml`**

Harus ada permission untuk Android 13+:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

✅ **Sudah ada di project Anda!**

---

## 3️⃣ Setup iOS FCM (APNs)

### ⚠️ Untuk iOS, Anda Butuh:
- **APNs Certificate** atau **APNs Auth Key** dari Apple Developer
- Ini BERBEDA dari Android!

### A. Generate APNs Auth Key (Recommended)

**Di Apple Developer Portal:**
```
https://developer.apple.com/account/
```

1. Klik **"Certificates, Identifiers & Profiles"** → **"Keys"**
2. Klik **"+"** untuk buat key baru
3. Pilih **"Apple Push Notifications service (APNs)"**
4. Klik **"Continue"** → **"Register"**
5. Download `.p8` file (SAVE BAIK-BAIK, CUMA BISA DOWNLOAD 1x!)
6. Catat **Key ID** (8 character, di sebelah key name)

### B. Upload ke Firebase

**Di Firebase Console:**
```
Project Settings (⚙️) → Cloud Messaging → iOS App Configuration
```

1. Scroll ke **"APNs Authentication Key"**
2. Klik **"Upload"** → Upload `.p8` file yang sudah di-download
3. Isi **Key ID** (8 character dari Apple Developer)
4. Isi **Team ID** (10 character, lihat di Apple Developer → Account)
5. Klik **"Upload"**

---

## 4️⃣ Ambil FCM Token

### A. Run App Pertama Kali

```bash
flutter clean
flutter pub get
flutter run
```

Perhatikan **Console Output** (Android Studio atau Terminal):
```
[PushService] Token init: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6...
[PushService] Subscribed: pengumuman-kampus
```

**Copy token tersebut!** (yang panjang itu)

### B. Alternative: Lihat di App Sendiri

Buka app → halaman HOME akan tampil token:
```
FCM Token: a1b2c3d4e5f6g7h8i9j0...  [Copy]
```

Klik tombol **"Copy"** untuk copy ke clipboard.

---

## 5️⃣ Test Notifikasi (Firebase Console)

### A. Buka Cloud Messaging

```
Firebase Console → Project → Cloud Messaging (kiri sidebar)
```

### B. Klik "Send Your First Message"

Atau klik **"Create Campaign"** → pilih **"Send notification to specific devices"**

### C. Compose Message

**Notification Tab:**
```
Title:       Pengumuman Penting
Body:        Silakan cek pengumuman terbaru dari kampus
```

**Target Tab:**
Pilih salah satu:

**Option 1: Kirim ke Topic (Semua Device yang Subscribe)**
```
Send by topic
Topic name: pengumuman-kampus
```

**Option 2: Kirim ke Device Spesifik**
```
Send by device token
Device token: [PASTE token yang sudah di-copy di Step 4]
```

Klik **"Send"**

### D. Extra: Tambah Deep Link (Data Payload)

**Sebelum klik "Send"**, klik tab **"Additional options"**

Scroll ke **"Custom data"**, klik **"Add parameter"**:
```
Key:   route
Value: /pengumuman/123
```

Ini adalah deep link yang akan di-handle oleh `push_service.dart`.

---

## 6️⃣ Test Tiga State Notifikasi

### State 1: FOREGROUND (App Terbuka)
```
1. Buka app (MainActivity terbuka)
2. Jangan tap apa-apa, biarkan terbuka
3. Kirim notifikasi dari Firebase Console (option 2 di atas)
   
Expected:
✅ Banner/dialog notifikasi muncul DI ATAS screen
✅ Jika ada data route, bisa tap → navigate
```

**Logs di console:**
```
[PushService Foreground] Pesan ditampilkan: ...
```

---

### State 2: BACKGROUND (App Diminimalkan)
```
1. Buka app
2. Tekan tombol HOME (app go to background)
3. Kirim notifikasi dari Firebase Console
   
Expected:
✅ Notifikasi muncul di notification tray (atas screen)
✅ Tap notifikasi → app open + navigate ke route
```

**Logs di console (saat tap):**
```
[PushService Background Click] Navigasi ke: /pengumuman/123
```

---

### State 3: TERMINATED (App Ditutup Total)
```
1. Buka app
2. Swipe up dari Recent Apps (kill app completely)
   ATAU Klik "Stop" di Android Studio
3. Kirim notifikasi dari Firebase Console
4. Buka notifikasi dari notification center (pull down dari atas)
   
Expected:
✅ App launch
✅ Auto-navigate ke route (/pengumuman/123)
```

**Logs di console (saat startup):**
```
[PushService] Token init: a1b2c3d4...
[PushService Terminated] Navigasi dari notifikasi: /pengumuman/123
```

---

## 7️⃣ Format Payload Referensi

### Payload Minimal (Hanya Notifikasi)
```json
{
  "to": "/topics/pengumuman-kampus",
  "notification": {
    "title": "Pengumuman Baru",
    "body": "Ada pengumuman terbaru untuk Anda"
  }
}
```

### Payload Lengkap (Notifikasi + Deep Link)
```json
{
  "to": "/topics/pengumuman-kampus",
  "notification": {
    "title": "Jadwal Kuliah Berubah",
    "body": "Pratikum 3 di pindahkan ke Rabu pukul 14:00"
  },
  "data": {
    "route": "/pengumuman/123",
    "announcement_id": "123",
    "priority": "high"
  }
}
```

### Payload ke Device Token Spesifik
```json
{
  "to": "cXB3OjIzNzI0NjplLXQyVjhDQU1FMDZfQlJCRkw6MDo...",
  "notification": {
    "title": "Notifikasi Personal",
    "body": "Ini notifikasi hanya untuk Anda"
  },
  "data": {
    "route": "/pengumuman/456"
  }
}
```

---

## 🐛 Troubleshooting

### ❌ Error: "App not registered with Firebase"

**Solusi:**
1. Pastikan `google-services.json` sudah di `android/app/`
2. Rebuild: `flutter clean` → `flutter pub get` → `flutter run`
3. Check di Firebase Console project Anda sudah register app Android

---

### ❌ Notifikasi Tidak Muncul di Foreground

**Checklist:**
- [ ] `listenForeground()` sudah di-call di `main.dart` initState
- [ ] Permission `POST_NOTIFICATIONS` sudah di-grant user
- [ ] `AndroidNotificationChannel` sudah dibuat dengan `Importance.high`
- [ ] Backend kirim ke topik yang benar: `pengumuman-kampus`

---

### ❌ Notifikasi Tidak Muncul di Background

**Checklist:**
- [ ] `onMessageOpenedApp` listener sudah setup
- [ ] Notification channel category benar
- [ ] Device tidak dalam "Do Not Disturb" mode
- [ ] Baterai tidak dalam Battery Saver mode

---

### ❌ iOS Notifikasi Tidak Muncul

**Checklist:**
- [ ] APNs Auth Key sudah di-upload ke Firebase Console
- [ ] APNs Key ID & Team ID benar
- [ ] App Bundle ID sama di Xcode & Firebase Console
- [ ] Push Notification capability ON di Xcode
- [ ] Build & run di physical device (simulator tidak support APNs)

---

### ❌ Token Tidak Muncul

**Solusi:**
```dart
// Di main.dart, check console output saat app startup
debugPrint('FCM token ready: $token');

// Jika blank, berarti:
// 1. Firebase belum initialize
// 2. Internet connection tidak tersedia
// 3. Google Play Services (Android) belum terinstall
```

---

## 📱 Device Setup

### Android Emulator (Firebase bisa kirim)

Pastikan emulator punya Google Play Services:
```bash
# Buat emulator dengan Google Play
Android Studio → Device Manager → Create Device
→ Pilih image dengan "Google Play" label
```

---

### Android Physical Device (Firebase bisa kirim)

1. Install app
2. Check permission di Settings → App permissions
3. Pastikan "Notification" permission di-grant

---

### iOS Simulator (⚠️ APNs NOT SUPPORTED)

Firebase FCM di iOS simulator **TIDAK JALAN** karena simulator tidak support APNs.

**Workaround:** Build & run di physical device:
```bash
# Cari connected physical devices
flutter devices

# Run di device
flutter run -d <device-id>
```

---

## ✅ Verification Checklist

- [ ] `google-services.json` di `android/app/`
- [ ] App registered di Firebase Console (Android)
- [ ] APNs setup di Firebase Console (iOS)
- [ ] `POST_NOTIFICATIONS` permission di AndroidManifest.xml
- [ ] `flutter pub get` setelah download `google-services.json`
- [ ] `flutter clean` → `flutter run`
- [ ] Test di semua 3 states (Foreground/Background/Terminated)
- [ ] Check logs: `flutter logs | grep "PushService"`
- [ ] Token muncul di Firebase Console Device Status

---

## 🎯 Next Steps

1. ✅ Setup Firebase Console (sudah di atas)
2. ✅ Download `google-services.json` & APNs key
3. ✅ Update Android/iOS config (sudah di atas)
4. ✅ Run app & copy token
5. ✅ Test notifikasi di Firebase Console (3 states)
6. ✅ Verify logs di console

**Jika semua ✅, notifikasi FCM sudah berfungsi 100%!**

---

Last Updated: October 4, 2026
