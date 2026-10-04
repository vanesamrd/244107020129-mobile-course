import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../messaging/push_service_class.dart';

// Args wrapper supaya provider bisa menerima onNavigate callback
class PushServiceArgs {
  const PushServiceArgs({required this.onNavigate});
  final void Function(String route) onNavigate;
}

// Provider untuk PushService class-based (menggunakan family)
final pushServiceProvider = Provider.family<PushService, PushServiceArgs>(
  (ref, args) {
    final mockDio = Dio(BaseOptions(
      baseUrl: 'https://example-campus-api.test',
      connectTimeout: const Duration(seconds: 5),
    ));

    final service = PushService(
      apiClient: mockDio,
      onNavigate: args.onNavigate,
    );

    // initialize() sudah dipanggil di main.dart (registerBackgroundHandler, dll)
    // PushService.initialize() di halaman demo dipanggil di initState via ref.read
    return service;
  },
);
