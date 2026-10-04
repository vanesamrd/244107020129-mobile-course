import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'message_parser.dart';

// ============================================================================
// 🔴 ATURAN KRITIS: BACKGROUND HANDLER
// ============================================================================
// ⚠️ JANGAN mengakses BuildContext, Riverpod ref, atau NavigatorKey di sini!
// ⚠️ Fungsi ini berjalan di Background Isolate terpisah (NO WIDGET TREE).
// ⚠️ Gunakan HANYA untuk logging atau penyimpanan data lokal (SharedPreferences/SQLite).
// ============================================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inisialisasi Firebase di isolate ini
  await Firebase.initializeApp();

  // Simpan ringan saja (logging, cache). Navigasi dilakukan saat klik notifikasi.
  debugPrint('[FCM Background] pesan: ${message.messageId}');
  debugPrint('[FCM Background] data: ${message.data}');
}

// ============================================================================
// Global state untuk mengelola navigasi dan listener
// ============================================================================
final _local = FlutterLocalNotificationsPlugin();
String? pendingDeepLink;
void Function(String route)? onNotificationTapped;

// ============================================================================
// 1. Register Background Handler
// ============================================================================
void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  debugPrint('[PushService] Background handler registered');
}

// ============================================================================
// 2. Request Notification Permission
// ============================================================================
/// Minta izin notifikasi runtime ke user.
///
/// 🔍 PERBEDAAN PLATFORM:
/// • **Android 13+ (API 33+)**:
///   - Izin runtime WAJIB diminta
///   - WAJIB ada tag `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
///     di `android/app/src/main/AndroidManifest.xml`
/// • **Android < 13**:
///   - Izin otomatis saat install (tidak butuh dialog)
/// • **iOS**:
///   - Izin runtime WAJIB diminta via APNs
///   - APNs Auth Key (.p8) harus sudah diunggah ke Firebase Console
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );

  final isGranted =
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  debugPrint('[PushService] Izin notifikasi: ${settings.authorizationStatus}');
  return isGranted;
}

// ============================================================================
// 3. Initialize Local Notifications
// ============================================================================
/// Setup local notifications untuk menampilkan banner saat app di foreground.
///
/// 🔍 PERBEDAAN PLATFORM:
/// • **Android < 8.0 (API < 26)**:
///   - Tidak butuh channel, notifikasi langsung tampil
/// • **Android 8.0+ (API 26+)** ← ⚠️ WAJIB buat channel!
///   - Butuh `AndroidNotificationChannel` dengan `Importance.high`
///   - Tanpa channel, heads-up banner TIDAK akan melayang di atas screen
/// • **iOS**:
///   - Gunakan `DarwinInitializationSettings`
///   - Tidak mengenal konsep "Channel"
///   - Konfigurasi alert/badge/sound via `DarwinNotificationDetails`
Future<void> initLocalNotifications() async {
  // Setup Android: icon launcher (@mipmap/ic_launcher)
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  // Setup iOS: minimal config (Android sudah handle izin via Firebase)
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  // Inisialisasi
  await _local.initialize(
    settings: const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
    onDidReceiveNotificationResponse: (response) {
      // Tangani klik notifikasi foreground → simpan deep link untuk navigasi
      pendingDeepLink = response.payload;
      if (response.payload != null) {
        onNotificationTapped?.call(response.payload!);
      }
    },
  );

  // ⚠️ KHUSUS ANDROID 8.0+ (API 26+): Buat notification channel
  if (Platform.isAndroid) {
    const channel = AndroidNotificationChannel(
      'pengumuman_channel',
      'Pengumuman Kampus',
      description: 'Notifikasi broadcast pengumuman penting akademik',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    debugPrint('[PushService] Android notification channel dibuat');
  }

  debugPrint('[PushService] Local notifications initialized');
}

// ============================================================================
// 4. Initialize FCM Token Lifecycle
// ============================================================================
/// Setup token: ambil, kirim ke backend, dan pantau refresh.
///
/// ⚠️ WAJIB menyimpan token lifecycle listener!
/// Token bisa berubah saat:
/// - User uninstall & reinstall app
/// - User clear app data
/// - Google Security Update (rotasi token)
/// Jika backend menyimpan token lama, notifikasi akan hilang.
Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  // 1. Ambil token saat ini
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    debugPrint('[PushService] Token init: ${token.substring(0, 20)}...');
    await onToken(token);
  }

  // 2. Pantau refresh token (⚠️ WAJIB ada!)
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('[PushService] Token refresh: ${newToken.substring(0, 20)}...');
    onToken(newToken);
  });

  // 3. Subscribe topik default kampus
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  debugPrint('[PushService] Subscribed: pengumuman-kampus');
}

// ============================================================================
// 5. Listen Foreground Messages
// ============================================================================
/// Setup handler untuk 2 state: Foreground (banner) dan Background click.
///
/// 🔍 Kenapa perlu listener terpisah?
/// Saat app di foreground, sistem Android/iOS TIDAK menampilkan banner otomatis.
/// Kita harus munculkan banner manual via local notification.
void listenForeground(void Function(String route) go) {
  // --------
  // A. FOREGROUND: tampilkan banner manual
  // --------
  FirebaseMessaging.onMessage.listen((message) async {
    // Parse route menggunakan pure function (bisa di-unit-test)
    final route = routeFromMessage(message.data);

    // 🔍 PLATFORM DETAILS:
    const androidDetails = AndroidNotificationDetails(
      'pengumuman_channel',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: route,
    );

    debugPrint(
      '[PushService Foreground] Pesan ditampilkan: ${message.messageId}',
    );
  });

  // --------
  // B. BACKGROUND: banner sistem muncul otomatis, handler ini dipanggil saat diklik
  // --------
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    // Parse route menggunakan pure function (bisa di-unit-test)
    final route = routeFromMessage(message.data);
    debugPrint('[PushService Background Click] Navigasi ke: $route');
    go(route);
  });
}

// ============================================================================
// 6. Handle Terminated State
// ============================================================================
/// Tangani deep link saat app dibuka dari state terminated (mati total).
///
/// 📌 Urutan pemanggilan saat app terminated:
/// 1. User tap notifikasi
/// 2. App startup
/// 3. `getInitialMessage()` dipanggil sekali (di sini!)
/// 4. Handler `onMessageOpenedApp` TIDAK dipanggil ulang
Future<void> handleTerminated(void Function(String route) go) async {
  // Ambil pesan yang membuka app dari state terminated
  final initial = await FirebaseMessaging.instance.getInitialMessage();

  if (initial != null) {
    // Parse route menggunakan pure function (bisa di-unit-test)
    final route = routeFromMessage(initial.data);
    debugPrint('[PushService Terminated] Navigasi dari notifikasi: $route');
    go(route);
  }

  // Fallback: jika ada pending deep link dari klik foreground banner
  if (pendingDeepLink != null) {
    debugPrint('[PushService Fallback] Navigasi ke pending: $pendingDeepLink');
    go(pendingDeepLink!);
    pendingDeepLink = null;
  }
}

// ============================================================================
// 7. Topic Management
// ============================================================================
Future<void> subscribeCampusTopic() async {
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  debugPrint('[PushService] Subscribe: pengumuman-kampus');
}

Future<void> unsubscribeCampusTopic() async {
  await FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');
  debugPrint('[PushService] Unsubscribe: pengumuman-kampus');
}
