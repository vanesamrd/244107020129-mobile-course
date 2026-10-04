# 🚀 Firebase FCM Setup - Visual Step-by-Step

## 📸 Screenshots Guide (Simulated Text Instructions)

### PHASE 1: Firebase Console Setup

---

#### Step 1: Buka Firebase Console
```
URL: https://console.firebase.google.com/
```

```
┌─────────────────────────────────────────┐
│ Google Firebase Console                 │
│ ===================================== │
│                                       │
│  My Projects                          │
│  ┌──────────────────────────────────┐ │
│  │ [+] Create a new project         │ │
│  └──────────────────────────────────┘ │
│                                       │
│  Existing Projects:                   │
│  • campus_notify (jika sudah ada)    │
│                                       │
└─────────────────────────────────────────┘
```

**Klik:** "Create a new project" atau "Select a project"

---

#### Step 2: Buat Project Baru

```
┌─────────────────────────────────────────┐
│ Create a project                        │
│ ===================================== │
│                                       │
│ Project name: [campus_notify______]  │
│                                       │
│ Location:     [Asia Southeast 1____]  │
│               (Jakarta - recommended) │
│                                       │
│ Analytics:    [✓] Enable             │
│                                       │
│                    [Cancel]  [Create] │
└─────────────────────────────────────────┘
```

**Klik:** "Create"

**Tunggu:** ~5 menit sampai selesai

---

### PHASE 2: Register Android App

---

#### Step 3: Add Android App

```
Firebase Console
  ↓
Project Settings (⚙️ di top-right)
  ↓
"Your apps" tab
  ↓
[+] Add app → Select "Android"
```

**Form:**
```
┌─────────────────────────────────────────┐
│ Add Android app to Campus Notify       │
│ ===================================== │
│                                       │
│ Package name:                         │
│ [com.example.campus_notify__________] │
│         ↑ Copy dari android/app/     │
│           build.gradle.kts            │
│                                       │
│ App nickname (optional):              │
│ [Campus Notify Android______________] │
│                                       │
│ Debug signing certificate SHA-1:      │
│ [klik link untuk auto-generate]      │
│                                       │
│              [Register app]           │
└─────────────────────────────────────────┘
```

**PENTING:** 
- Copy package name dari `android/app/build.gradle.kts` (cari `namespace` atau `applicationId`)
- SHA-1 bisa di-skip dulu (opsional)

---

#### Step 4: Download google-services.json

Setelah register, Firebase akan show:
```
┌──────────────────────────────────────────┐
│                                          │
│  1️⃣  Download google-services.json       │
│     [Download] button                    │
│                                          │
│  2️⃣  Add the Firebase Android SDK       │
│     (copy gradle config)                 │
│                                          │
│  3️⃣  Add initialization code            │
│     (already in main.dart)               │
│                                          │
│                           [Next] [Skip]  │
└──────────────────────────────────────────┘
```

**ACTION:**
1. **DOWNLOAD** `google-services.json`
2. Copy ke: `android/app/google-services.json`

**CONFIRM:**
```
File explorer: 
android/
  ├── app/
  │   ├── build.gradle.kts
  │   ├── google-services.json ← DI SINI!
  │   └── src/
  ├── build.gradle.kts
  └── settings.gradle.kts
```

---

### PHASE 3: Setup iOS (Optional tapi PENTING untuk iOS)

---

#### Step 5: Generate APNs Key (Apple Developer)

Buka: https://developer.apple.com/account/

```
1. Login dengan Apple ID
2. Klik "Certificates, Identifiers & Profiles"
   ↓
3. Sidebar kiri: "Keys"
   ↓
4. [+] Create a New Key
   ↓
5. Checkbox "Apple Push Notifications service (APNs)"
   ↓
6. Klik "Continue" → "Register"
   ↓
7. [⬇️ Download] 
   ↓
   Save file: campus_notify_apns_key.p8
```

**CATAT:**
- Key ID: __________ (8 characters)
- Team ID: __________ (10 characters, di top-right Account page)

---

#### Step 6: Upload APNs ke Firebase

Firebase Console:
```
Project Settings (⚙️) → Cloud Messaging tab
```

```
┌──────────────────────────────────────────┐
│ iOS App Configuration                    │
│                                          │
│ APNs Authentication Key                  │
│ ┌──────────────────────────────────────┐ │
│ │ [Upload]                             │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ After upload:                            │
│ Key ID: [cXp9aB1234____________]        │
│ Team ID: [AB123CD456____________]       │
│                                          │
│                             [Save]      │
└──────────────────────────────────────────┘
```

---

### PHASE 4: Run App & Get Token

---

#### Step 7: Clean & Run

```bash
$ cd /Users/vanesshh/244107020129-mobile-course/06-week-6-authentication-security-fcm

$ flutter clean
Cleaning Gradle build...
✓ Clean complete

$ flutter pub get
Running "flutter pub get" in campus_notify...
Running "flutter packages get" in packages/...
✓ Packages get complete

$ flutter run
Launching lib/main.dart on Android...
✓ Built build/app/outputs/flutter-app.apk
Installing and launching...

Running flutter logs...

[PushService] Izin notifikasi: AuthorizationStatus.authorized
[PushService] Local notifications initialized
[PushService] Token init: 
    abcd1234efgh5678ijkl9012mnop3456...
[PushService] Subscribed: pengumuman-kampus
```

**COPY TOKEN:** 
```
abcd1234efgh5678ijkl9012mnop3456...
     ↑
   Simpan di Notepad untuk nanti
```

---

### PHASE 5: Send Test Notification

---

#### Step 8: Firebase Console - Send Message

```
Firebase Console → Project → Cloud Messaging (left sidebar)
```

```
┌──────────────────────────────────────────┐
│ Cloud Messaging                          │
│                                          │
│ [Send your first message]                │
│ atau                                     │
│ [Compose notification]                   │
└──────────────────────────────────────────┘
```

Klik **"Compose notification"**

---

#### Step 9: Fill Notification Details

```
┌──────────────────────────────────────────┐
│ Compose notification                     │
│ ===================================== │
│                                       │
│ Title *                               │
│ [Pengumuman Penting______________]   │
│                                       │
│ Text *                                │
│ [Silakan cek pengumuman terbaru____] │
│                                       │
│    [+ Add more options]               │
│                                       │
│ Next step: "Target"                   │
└──────────────────────────────────────────┘
```

Klik **"Next"** (atau "Next step: Target")

---

#### Step 10: Choose Target

```
┌──────────────────────────────────────────┐
│ Select target                            │
│ ===================================== │
│                                       │
│ Choose an option:                     │
│ ◉ Topic          (✓ Recommended)     │
│ ○ Device token                        │
│ ○ Condition                           │
│                                       │
│ [Selected] Topic: pengumuman-kampus  │
│                                       │
│ Topic list:                           │
│ • pengumuman-kampus                   │
│   [Select]                            │
│                                       │
└──────────────────────────────────────────┘
```

**Pilih:** `pengumuman-kampus` (TopicName)

Atau jika ingin test ke device spesifik:
```
◉ Device token
[abcd1234efgh5678ijkl9012mnop3456...]
   ↑ Paste token dari Step 7
```

---

#### Step 11: Add Deep Link (Optional but Recommended)

```
[+ Additional options]
  ↓
Scroll down ke "Custom data"
  ↓
[+ Add parameter]
```

```
Key:   route
Value: /pengumuman/123
```

**Result:**
```
Custom data:
┌─────────────┬──────────────────────┐
│ Key         │ Value                │
├─────────────┼──────────────────────┤
│ route       │ /pengumuman/123      │
└─────────────┴──────────────────────┘
```

---

#### Step 12: Review & Send

```
┌──────────────────────────────────────────┐
│ Review                                   │
│ ===================================== │
│                                       │
│ Notification:                         │
│ Title: Pengumuman Penting             │
│ Body: Silakan cek pengumuman terbaru  │
│                                       │
│ Target:                               │
│ Topic: pengumuman-kampus              │
│                                       │
│ Additional data:                      │
│ route: /pengumuman/123                │
│                                       │
│ Schedule: Send now                    │
│                                       │
│               [Back]  [Publish]       │
└──────────────────────────────────────────┘
```

Klik **"Publish"**

**Status:**
```
✓ Messages delivered: 1
  Success rate: 100%
```

---

### PHASE 6: Verify on Device

---

#### Scenario A: App di FOREGROUND

```
Kondisi:
• App terbuka
• Halaman HOME terlihat

Saat receive notification:
┌─────────────────────────────────────┐
│ 🔔 Pengumuman Penting               │
│ Silakan cek pengumuman terbaru       │
│                                     │
│ [Tap untuk navigate]                │
└─────────────────────────────────────┘

Expected behavior:
✅ Banner/dialog muncul
✅ Tap → navigate ke /pengumuman/123

Logs:
[PushService Foreground] Pesan ditampilkan: ...
```

---

#### Scenario B: App di BACKGROUND

```
Kondisi:
• App di-minimize (tekan HOME)
• Notifikasi di tray

Pull down notification tray:
┌──────────────────────────────┐
│ 🔔 Pengumuman Penting        │
│    Silakan cek...            │
│                              │
│ [Tap to open app]            │
└──────────────────────────────┘

Expected behavior:
✅ App buka
✅ Auto-navigate ke /pengumuman/123

Logs (saat tap):
[PushService Background Click] Navigasi ke: /pengumuman/123
```

---

#### Scenario C: App TERMINATED (Ditutup Total)

```
Kondisi:
• App sudah di-close (swipe from recents)
• Device di-lock atau background

Notification center (pull from top):
┌────────────────────────────────────┐
│ 🔔 Pengumuman Penting              │
│    Silakan cek pengumuman terbaru   │
│    [time: 10:45 AM]                │
│                                    │
│ [Tap atau click]                   │
└────────────────────────────────────┘

Expected behavior:
✅ App launch
✅ Splash screen
✅ Auto-navigate ke /pengumuman/123

Logs (saat startup):
[PushService] Token init: abcd1234...
[PushService Terminated] Navigasi dari notifikasi: /pengumuman/123
```

---

## 🎯 Troubleshooting Quick Table

| Problem | Check This | Solution |
|---------|-----------|----------|
| Notif tidak muncul di Foreground | `listenForeground()` di main.dart | Pastikan sudah di-call di initState |
| Notif tidak muncul di Background | `onMessageOpenedApp` listener | Bandingkan dengan docs di push_service.dart |
| Token blank/null | Internet + Google Play Services | Restart device, clear cache |
| iOS notif tidak jalan | APNs key di Firebase | Download & upload APNs dari Apple Developer |
| Can't send ke topic | Topic name di Firebase Console | Pastikan nama topik: `pengumuman-kampus` |
| Deep link tidak jalan | Route format di data payload | Harus format `/pengumuman/123` (matches route regex) |

---

## 📋 Verification Checklist (Final)

```
Setup Android:
✓ google-services.json di android/app/
✓ POST_NOTIFICATIONS permission di AndroidManifest.xml
✓ build.gradle.kts punya google-services plugin

Setup iOS (optional):
✓ APNs Auth Key di-upload ke Firebase
✓ Team ID & Key ID benar

App Setup:
✓ flutter clean + flutter pub get
✓ Token muncul di console logs
✓ App di Firebase Console sudah terdaftar

Testing:
✓ Test Foreground (notif muncul)
✓ Test Background (notif muncul + tap → navigate)
✓ Test Terminated (restart app → navigate)
✓ Semua 3 scenarios berjalan OK
```

---

## ✅ Jika Semua Sukses

```
• Notifikasi muncul di device
• Tap notifikasi → app navigate ke /pengumuman/123
• Logs clear dan informatif
• Tidak ada crash

🎉 FCM Setup Complete! 🎉
```

---

**Need Help?** Refer ke:
- `FIREBASE_FCM_SETUP.md` - Detailed setup guide
- `IMPLEMENTATION_GUIDE.md` - PushService code explanation
- `push_service.dart` - Source code dengan comments
