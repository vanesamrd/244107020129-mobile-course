import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import 'messaging/push_service.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import 'pages/push_service_demo_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  registerBackgroundHandler();
  await requestNotificationPermission();
  await initLocalNotifications();
  await initFcmToken(
    onToken: (token) async {
      debugPrint('FCM token ready: $token');
    },
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      redirect: (context, state) {
        final loggedIn = ref.read(authStateProvider).value ?? false;
        final goingLogin = state.matchedLocation == AppRoutes.login;
        if (!loggedIn && !goingLogin) return AppRoutes.login;
        if (loggedIn && goingLogin) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.announcementPathTemplate,
          builder: (context, state) => AnnouncementPage(
            id: AppRoutes.extractAnnouncementId(state.pathParameters) ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.pushServiceDemo,
          builder: (context, state) => const PushServiceDemoPage(),
        ),
      ],
    );

    // Setup handler klik notifikasi saat foreground
    onNotificationTapped = (route) => _router.go(route);

    // Setup listener foreground dan background click
    listenForeground((route) => _router.go(route));

    // Handle deep link atau notifikasi saat aplikasi dibuka dari keadaan terminated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleTerminated((route) => _router.go(route));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan auth state agar GoRouter melakukan refresh otomatis
    ref.listen(authStateProvider, (previous, next) {
      _router.refresh();
    });

    return MaterialApp.router(title: 'Campus Notify', routerConfig: _router);
  }
}
