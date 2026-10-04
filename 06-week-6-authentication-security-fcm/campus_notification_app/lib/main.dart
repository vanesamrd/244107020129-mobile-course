import 'package:flutter/material.dart';
import 'services/secure_storage_service.dart';
import 'services/dio_client.dart';
import 'services/fcm_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = SecureStorageService();
  final appRouter = AppRouter(secureStorage: secureStorage);

  // Inisialisasi Dio Client
  final dioClient = DioClient(
    secureStorage: secureStorage,
    onSessionExpired: () {
      appRouter.router.go('/login');
    },
  );

  // Inisialisasi FCM Service
  final fcmService = FcmService(
    onNavigate: (route) {
      appRouter.router.push(route);
    },
  );

  runApp(CampusApp(appRouter: appRouter));
}

class CampusApp extends StatelessWidget {
  final AppRouter appRouter;
  const CampusApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UniNotify Campus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter.router,
    );
  }
}
