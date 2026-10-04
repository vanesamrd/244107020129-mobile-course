# 📱 PushService Implementation Guide

## 📋 Ringkasan Lengkap

Aplikasi **Campus Notification App** menggunakan Firebase Cloud Messaging (FCM) untuk mengirim notifikasi real-time. Implementasi dibagi menjadi **2 file** untuk fleksibilitas:

### 1. **`push_service.dart`** - Functional Approach (Yang Digunakan di `main.dart`)
Top-level functions yang mudah dipanggil langsung di `main()`:
- `registerBackgroundHandler()` - Daftarkan handler background
- `requestNotificationPermission()` - Minta izin notifikasi
- `initLocalNotifications()` - Setup banner lokal
- `initFcmToken()` - Ambil token dan monitor refresh
- `listenForeground()` - Setup handler foreground & background click
- `handleTerminated()` - Handle deep link saat app dibuka dari notifikasi

### 2. **`push_service_class.dart`** - OOP Approach (Optional, untuk Provider)
Class `PushService` yang bisa diinject via Riverpod Provider:
```dart
final pushServiceProvider = Provider<PushService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PushService(
    apiClient: dio,
    onNavigate: (route) => _router.go(route),
  );
});
```

---

## 🔍 Perbedaan Platform: Android 13+ vs iOS

### 📱 Android 13+ (API 33+)

| Aspek | Keterangan | File | Baris |
|-------|-----------|------|-------|
| **Permission Runtime** | ✅ WAJIB dipanggil | `push_service.dart` | 52-68 |
| **AndroidManifest.xml** | ✅ WAJIB ada `POST_NOTIFICATIONS` | `android/app/src/main/AndroidManifest.xml` | 2 |
| **Notification Channel** | ✅ WAJIB dibuat dengan `Importance.high` | `push_service.dart` | 103-118 |
| **Ikon Notifikasi** | Monokromatik `@mipmap/ic_launcher` | `push_service.dart` | 91 |
| **Local Notification Details** | `AndroidNotificationDetails` | `push_service.dart` | 158-162 |

```dart
// Android 13+: Channel WAJIB
const channel = AndroidNotificationChannel(
  'pengumuman_channel',
  'Pengumuman Kampus',
  importance: Importance.high,  // ← WAJIB untuk heads-up banner
);
await _local.resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
```

### 🍎 iOS

| Aspek | Keterangan | File | Baris |
|-------|-----------|------|-------|
| **Permission Runtime** | ✅ WAJIB dipanggil | `push_service.dart` | 52-68 |
| **APNs Configuration** | ✅ Sertifikat/Auth Key (.p8) di Firebase Console | Manual di Firebase | - |
| **Notification Channel** | ❌ Tidak ada konsep channel | N/A | - |
| **Local Notification Details** | `DarwinNotificationDetails` | `push_service.dart` | 98-102 |

```dart
// iOS: Cukup DarwinInitializationSettings
const iosSettings = DarwinInitializationSettings(
  requestAlertPermission: false,  // Sudah di-handle Firebase
  requestBadgePermission: false,
  requestSoundPermission: false,
);
```

---

## 🔴 Aturan KRITIS: Jangan Akses `BuildContext` di Mana?

### ❌ DILARANG di Background Handler

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ❌ LARANG BuildContext – tidak ada widget tree!
  // ❌ LARANG Riverpod ref – tidak ada ProviderContainer!
  // ❌ LARANG NavigatorKey – isolate terpisah!
  
  // ✅ BOLEH:
  await Firebase.initializeApp();
  debugPrint('message: ${message.data}');  // Logging ringan
}
```

**Kenapa dilarang?**
- Fungsi berjalan di **Background Isolate** yang terisolasi dari main UI thread
- Tidak ada UI / Widget Tree yang aktif
- Tidak ada Provider Scope yang aktif
- Akses akan menghasilkan crash: `NoSuchMethodError` atau null pointer

**Solusi:** Simpan data lokal saja (SQLite/SharedPreferences). Navigasi dilakukan saat user mengklik notifikasi.

### ✅ DIBOLEHKAN untuk Navigasi

```dart
void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final route = message.data['route'] ?? '/';
    // ✅ BOLEH: Callback dibuat saat UI active
    go(route);  // Panggil: _router.go(route) dari main.dart
  });
}
```

---

## 📊 Lifecycle Tiga State Aplikasi

### State 1️⃣: **FOREGROUND** (App Sedang Terbuka di Layar)

```
Firebase msg diterima
       ↓
Sistem Android/iOS TIDAK menampilkan banner otomatis
       ↓
onMessage listener dipanggil
       ↓
Tampilkan banner manual via _local.show()
```

**File:** `push_service.dart` baris 127-162

### State 2️⃣: **BACKGROUND** (App Diminimalkan)

```
Firebase msg diterima
       ↓
Sistem Android/iOS menampilkan banner OTOMATIS
       ↓
User klik banner
       ↓
onMessageOpenedApp listener dipanggil
       ↓
Navigasi ke route dari data['route']
```

**File:** `push_service.dart` baris 165-170

### State 3️⃣: **TERMINATED** (App Mati Total)

```
Firebase msg diterima
       ↓
Sistem Android/iOS menampilkan banner di notification center
       ↓
User klik banner → Launch app
       ↓
App startup completes
       ↓
getInitialMessage() dipanggil SEKALI
       ↓
Navigasi ke route dari data['route']
```

**File:** `push_service.dart` baris 173-188

---

## 🚀 Cara Integration dengan `main.dart`

### Step 1: Inisialisasi Firebase & PushService

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Daftarkan background handler
  registerBackgroundHandler();
  
  // Setup permission & local notifications
  await requestNotificationPermission();
  await initLocalNotifications();
  
  // Ambil token & monitor refresh
  await initFcmToken(
    onToken: (token) async {
      debugPrint('FCM token: $token');
      // TODO: Kirim ke backend via POST /devices
    },
  );

  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 2: Setup Navigation Handlers di `initState`

```dart
class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(routes: [...]);

    // Setup callback untuk klik banner foreground
    onNotificationTapped = (route) => _router.go(route);

    // Setup listener untuk klik banner saat app di foreground/background
    listenForeground((route) => _router.go(route));

    // Handle deep link dari notifikasi saat terminated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleTerminated((route) => _router.go(route));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}
```

---

## 📲 Format Payload FCM Message

Backend harus mengirim pesan dengan format berikut:

```json
{
  "to": "fcm_token_atau_topic",
  "notification": {
    "title": "Pengumuman Akademik",
    "body": "Lihat pengumuman terbaru dari kampus"
  },
  "data": {
    "route": "/pengumuman/123"
  }
}
```

---

## ✔️ Checklist Android 13+

- [ ] `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` ada di `AndroidManifest.xml` baris 2
- [ ] `requestNotificationPermission()` dipanggil di `main()`
- [ ] `AndroidNotificationChannel` dibuat dengan `Importance.high`
- [ ] `channel ID` di banner (`pengumuman_channel`) sesuai dengan yang dibuat
- [ ] Target SDK minimal 33 di `build.gradle`

## ✔️ Checklist iOS

- [ ] APNs Auth Key (.p8) sudah diunggah ke Firebase Console
- [ ] `requestNotificationPermission()` dipanggil di `main()`
- [ ] `DarwinInitializationSettings` dikonfigurasi dengan `requestAlert/Badge/Sound: false`
- [ ] App Bundle ID di Xcode sama dengan di Firebase Console

---

## 🐛 Troubleshooting

### ❓ Q: Notifikasi tidak muncul di Android Foreground
**A:** Check bahwa:
1. `onMessage` listener sudah dipanggil via `listenForeground()`
2. `AndroidNotificationChannel` sudah dibuat dengan `Importance.high`
3. `Permission.POST_NOTIFICATIONS` sudah di-grant

### ❓ Q: Background Handler Crash
**A:** Jangan akses `BuildContext` atau `Riverpod ref` di handler. Hanya lakukan logging/storage lokal.

### ❓ Q: Token tidak dikirim ke backend
**A:** Check bahwa:
1. `initFcmToken()` sudah dipanggil
2. `onTokenRefresh` listener sudah dipasang
3. Backend endpoint `/devices` sudah benar

### ❓ Q: iOS tidak menerima notifikasi
**A:** Verify:
1. APNs certificate di Firebase Console valid & belum expired
2. App ID di Xcode sama dengan di Apple Developer
3. Push Notification capability diaktifkan di Xcode

---

## 📚 File Reference

```
lib/messaging/
├── push_service.dart              # Functional API (digunakan di main.dart)
├── push_service_class.dart        # Class-based API (opsional, untuk Provider)
└── IMPLEMENTATION_GUIDE.md        # Doc ini
```

---

**Last Updated:** October 4, 2026  
**Author:** AI Coding Assistant  
**Status:** Production Ready ✅
