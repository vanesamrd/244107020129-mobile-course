import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';

typedef OnNotificationNavigation = void Function(String route);

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final String backendUrl;
  final OnNotificationNavigation onNavigate;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Token terpotong (masked) untuk keamanan: 'fcm_e8K9...zQ2x'
  String get maskedToken {
    if (_fcmToken == null || _fcmToken!.length <= 14) {
      return 'fcm_token_ready...';
    }
    return '${_fcmToken!.substring(0, 8)}...${_fcmToken!.substring(_fcmToken!.length - 6)}';
  }

  FcmService({
    required this.onNavigate,
    this.backendUrl = 'https://api.kampus.ac.id',
  });

  Future<void> initialize() async {
    // 1. Minta izin notifikasi
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Ambil Device Token
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        await _registerDeviceToBackend(_fcmToken!);
      }

      // 3. Listener onTokenRefresh: otomatis kirim ke backend jika token berubah
      _fcm.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await _registerDeviceToBackend(newToken);
      });

      // 4. Berlangganan topik wajib universitas
      await _fcm.subscribeToTopic('pengumuman-kampus');

      // 5. Setup 3 Kondisi Aplikasi
      _setupForegroundHandler();
      _setupBackgroundHandler();
      await _setupTerminatedInitialMessage();
    }
  }

  /// Sinkronisasi ke Endpoint Backend POST /devices
  Future<void> _registerDeviceToBackend(String token) async {
    try {
      final dio = Dio();
      await dio.post(
        '$backendUrl/devices',
        data: {
          'fcmToken': token,
          'platform': 'flutter_android_ios',
          'subscribedTopics': ['pengumuman-kampus'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  /// 1. State Foreground (Aplikasi sedang aktif terbuka di layar)
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final route = extractRouteFromMessage(message);
      if (route != null) {
        onNavigate(route);
      }
    });
  }

  /// 2. State Background (Aplikasi diminimalkan, diklik dari bar notifikasi)
  void _setupBackgroundHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = extractRouteFromMessage(message);
      if (route != null) {
        onNavigate(route);
      }
    });
  }

  /// 3. State Terminated (Aplikasi mati di RAM, dibuka via notifikasi / Cold-Start)
  Future<void> _setupTerminatedInitialMessage() async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      final route = extractRouteFromMessage(initialMessage);
      if (route != null) {
        onNavigate(route);
      }
    }
  }

  /// Helper untuk mengekstrak rute deep link dari notification + data
  static String? extractRouteFromMessage(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('route') && data['route'].toString().isNotEmpty) {
      return data['route'];
    }
    if (data.containsKey('id') && data['id'].toString().isNotEmpty) {
      return '/pengumuman/${data['id']}';
    }
    return null;
  }
}
