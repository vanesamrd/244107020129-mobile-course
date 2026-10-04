import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/secure_storage_service.dart';

class AppRouter {
  final SecureStorageService secureStorage;

  AppRouter({required this.secureStorage});

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final redirectPath = state.uri.queryParameters['redirect'];
          return LoginScreen(
              redirectPath: redirectPath, secureStorage: secureStorage);
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/pengumuman/:id',
        builder: (context, state) {
          final announcementId = state.pathParameters['id'] ?? '';
          return AnnouncementDetailScreen(id: announcementId);
        },
      ),
    ],
    // GUARD ROUTE: Memeriksa token sebelum mengakses rute
    redirect: (BuildContext context, GoRouterState state) async {
      final isLoggedIn = await secureStorage.hasValidSession();
      final isLoggingIn = state.matchedLocation == '/login';

      // 1. Belum login & mencoba membuka halaman tujuan (misal /pengumuman/krs):
      if (!isLoggedIn && !isLoggingIn) {
        final target = state.uri.toString();
        return '/login?redirect=${Uri.encodeComponent(target)}';
      }

      // 2. Sudah login tapi membuka halaman /login:
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
  );
}

// --- Screen Sederhana Sebagai Tampilan Contoh ---

class LoginScreen extends StatelessWidget {
  final String? redirectPath;
  final SecureStorageService secureStorage;
  const LoginScreen(
      {super.key, this.redirectPath, required this.secureStorage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Kampus')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Simulasi Login Mahasiswa
            await secureStorage.saveTokens(
              accessToken: 'jwt_access_valid',
              refreshToken: 'jwt_refresh_valid',
            );
            if (context.mounted) {
              if (redirectPath != null && redirectPath!.isNotEmpty) {
                context.go(redirectPath!);
              } else {
                context.go('/');
              }
            }
          },
          child: const Text('Masuk sebagai Mahasiswa (Demo)'),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman Kampus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Jadwal KRS Semester Ganjil 2026/2027'),
            subtitle: const Text('Klik untuk melihat detail'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/pengumuman/krs-ganjil-2026'),
          ),
        ],
      ),
    );
  }
}

class AnnouncementDetailScreen extends StatelessWidget {
  final String id;
  const AnnouncementDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman: $id')),
      body: Center(
        child: Text(
          'Detail Pengumuman ID: $id\nDeep link berhasil dibuka!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
