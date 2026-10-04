import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'message_parser.dart';

// ============================================================================
// ⚠️ TIDAK BOLEH MENGAKSES BuildContext / Riverpod di sini!
// ⚠️ Berjalan di Background Isolate terpisah, widget tree TIDAK ada.
// ============================================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[PushService] background msg: ${message.messageId}');
}

class PushService {
  PushService({required this._apiClient, required this._onNavigate});

  final Dio _apiClient;

  // ⚠️ Simpan sebagai callback, BUKAN BuildContext.
  // Gunakan router.go() / navigatorKey.currentContext dari luar.
  final void Function(String route) _onNavigate;

  final _local = FlutterLocalNotificationsPlugin();

  static const _campusTopic = 'pengumuman-kampus';

  // --------------------------------------------------------------------------
  // 1. Inisialisasi – panggil sekali sebelum runApp (atau di initState awal)
  // --------------------------------------------------------------------------
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await requestPermission();
    await _initLocalNotifications();
    await _setupTokenLifecycle();
    _setupMessageHandlers();
    await subscribeCampusTopic();
  }

  // --------------------------------------------------------------------------
  // 2. requestPermission – minta izin notifikasi runtime
  //
  // 🔍 ANDROID 13+ (API 33+):
  //   - Perlu <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  //     di AndroidManifest.xml.
  //   - requestPermission() di sini memunculkan dialog izin sistem Android.
  //
  // 🔍 iOS:
  //   - requestPermission() memunculkan dialog APNS bawaan iOS.
  //   - Perlu APNs Auth Key (.p8) yang sudah diunggah ke Firebase Console.
  // --------------------------------------------------------------------------
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    debugPrint('[PushService] permission: ${settings.authorizationStatus}');
    return granted;
  }

  // --------------------------------------------------------------------------
  // 3. Local Notifications – banner manual saat foreground
  //
  // 🔍 ANDROID:
  //   - Butuh AndroidInitializationSettings (nama icon launcher).
  //   - Android 8.0+ (API 26+): WAJIB buat NotificationChannel dengan
  //     Importance.high agar heads-up banner tampil di atas layar.
  //
  // 🔍 iOS:
  //   - Butuh DarwinInitializationSettings.
  //   - presentAlert/Badge/Sound: false karena izin sudah dihandle Firebase.
  //   - Tidak mengenal konsep "Channel".
  // --------------------------------------------------------------------------
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        // Klik banner foreground -> navigasi ke payload route
        if (response.payload != null && response.payload!.isNotEmpty) {
          _onNavigate(response.payload!);
        }
      },
    );

    // 🔍 KHUSUS ANDROID 8.0+ (API 26+): buat channel dengan prioritas tinggi
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
    }
  }

  // --------------------------------------------------------------------------
  // 4. Token Lifecycle – getToken, onTokenRefresh, kirim ke POST /devices
  // --------------------------------------------------------------------------
  Future<void> _setupTokenLifecycle() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('[PushService] token: ${token.substring(0, 16)}...');
      await _sendTokenToBackend(token);
    }

    // Listener WAJIB ada – token bisa berubah saat reinstall / clear data /
    // rotasi keamanan Google. Tanpa ini backend menyimpan token basi.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint(
        '[PushService] token refresh: ${newToken.substring(0, 16)}...',
      );
      await _sendTokenToBackend(newToken);
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      // ⚠️ Ganti baseUrl Dio dengan URL backend kampus Anda yang sesungguhnya.
      await _apiClient.post(
        '/devices',
        data: {
          'fcm_token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
      debugPrint('[PushService] token terkirim ke backend');
    } catch (e) {
      // Tidak crash – backend mock akan menolak, ini normal untuk demo.
      debugPrint('[PushService] gagal kirim token (mock backend): $e');
    }
  }

  // --------------------------------------------------------------------------
  // 5. Tiga State Handler
  // --------------------------------------------------------------------------
  void _setupMessageHandlers() {
    // A. FOREGROUND – aplikasi terbuka di layar.
    //    Sistem TIDAK menampilkan banner otomatis, harus manual via local notif.
    FirebaseMessaging.onMessage.listen((message) async {
      // Parse route menggunakan pure function (bisa di-unit-test)
      final route = routeFromMessage(message.data);
      await _local.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman Baru',
        body: message.notification?.body ?? '',
        notificationDetails: NotificationDetails(
          android: const AndroidNotificationDetails(
            'pengumuman_channel',
            'Pengumuman Kampus',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: route,
      );
    });

    // B. BACKGROUND – aplikasi diminimalkan, banner sistem muncul otomatis.
    //    Handler ini terpanggil SAAT USER MENGKLIK banner tersebut.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Parse route menggunakan pure function (bisa di-unit-test)
      final route = routeFromMessage(message.data);
      if (route.isNotEmpty) _onNavigate(route);
    });

    // C. TERMINATED – aplikasi mati total, dibuka lewat klik banner.
    //    Pesan diambil via getInitialMessage (dipanggil sekali saat startup).
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      // Parse route menggunakan pure function (bisa di-unit-test)
      final route = routeFromMessage(message.data);
      if (route.isNotEmpty) _onNavigate(route);
    });
  }

  // --------------------------------------------------------------------------
  // 6. Topic Messaging – subscribe / unsubscribe
  //
  // Gunakan topic untuk broadcast: semua mahasiswa, satu angkatan, satu UKM.
  // Untuk pesan personal (nilai, tagihan) → gunakan token perangkat, BUKAN topic.
  // --------------------------------------------------------------------------
  Future<void> subscribeCampusTopic() async {
    await FirebaseMessaging.instance.subscribeToTopic(_campusTopic);
    debugPrint('[PushService] subscribed: $_campusTopic');
  }

  Future<void> unsubscribeCampusTopic() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(_campusTopic);
    debugPrint('[PushService] unsubscribed: $_campusTopic');
  }
}
