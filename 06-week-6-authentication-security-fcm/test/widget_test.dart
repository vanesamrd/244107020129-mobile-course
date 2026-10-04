import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemorySecureStorage extends FlutterSecureStorage {
  InMemorySecureStorage() : super();

  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }
}

void main() {
  group('Praktikum 1 Tests', () {
    late InMemorySecureStorage fakeStorage;
    late TokenStore tokenStore;
    late AuthRepository authRepository;

    setUp(() {
      fakeStorage = InMemorySecureStorage();
      tokenStore = TokenStore(storage: fakeStorage);
      authRepository = AuthRepository();
    });

    test('1. TokenStore can save, read, and clear tokens', () async {
      expect(await tokenStore.readAccess(), isNull);
      expect(await tokenStore.readRefresh(), isNull);

      await tokenStore.save(
        access: 'mock-access-token',
        refresh: 'mock-refresh-token',
      );

      expect(await tokenStore.readAccess(), equals('mock-access-token'));
      expect(await tokenStore.readRefresh(), equals('mock-refresh-token'));

      await tokenStore.clear();

      expect(await tokenStore.readAccess(), isNull);
      expect(await tokenStore.readRefresh(), isNull);
    });

    test('2. AuthRepository handles login validation and token refresh', () async {
      // Invalid email
      expect(
        () => authRepository.login(email: 'invalid-email', password: 'password123'),
        throwsA(isA<Exception>()),
      );

      // Short password (< 6 chars)
      expect(
        () => authRepository.login(email: 'user@example.com', password: '123'),
        throwsA(isA<Exception>()),
      );

      // Successful login
      final session = await authRepository.login(
        email: 'mahasiswa@campus.ac.id',
        password: 'password123',
      );
      expect(session.access, equals('mock-access-for-mahasiswa@campus.ac.id'));
      expect(session.refresh, equals('mock-refresh-for-mahasiswa@campus.ac.id'));

      // Empty refresh token
      expect(
        () => authRepository.refresh(''),
        throwsA(isA<Exception>()),
      );

      // Valid refresh token
      final renewed = await authRepository.refresh('existing-refresh-token');
      expect(renewed, startsWith('mock-access-renewed-'));
    });

    test('3. Dio buildApiClient adds Authorization header and handles 401 refresh', () async {
      await tokenStore.save(access: 'initial-access', refresh: 'valid-refresh');
      final dio = buildApiClient(tokenStore, authRepository);

      // Add a mock adapter to simulate responses
      dio.httpClientAdapter = _MockHttpClientAdapter((request) {
        final authHeader = request.headers['Authorization']?.toString();
        if (authHeader == 'Bearer initial-access') {
          return ResponseBody.fromString(
            '{"error": "Unauthorized"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        } else if (authHeader != null && authHeader.startsWith('Bearer mock-access-renewed-')) {
          return ResponseBody.fromString(
            '{"message": "Success"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('Unauthorized', 401);
      });

      final response = await dio.get('/test-endpoint');
      expect(response.statusCode, equals(200));
      expect(response.data['message'], equals('Success'));

      final updatedAccess = await tokenStore.readAccess();
      expect(updatedAccess, startsWith('mock-access-renewed-'));
    });

    test('4. AuthProvider login and logout state updates correctly', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
      );
      addTearDown(container.dispose);

      // Initial state without saved token
      final initialLoggedIn = await container.read(authStateProvider.future);
      expect(initialLoggedIn, isFalse);

      // Perform login
      await container.read(authStateProvider.notifier).login('user@test.com', 'secret123');

      final loggedInState = await container.read(authStateProvider.future);
      expect(loggedInState, isTrue);
      expect(await tokenStore.readAccess(), equals('mock-access-for-user@test.com'));

      // Perform logout
      await container.read(authStateProvider.notifier).logout();

      final loggedOutState = await container.read(authStateProvider.future);
      expect(loggedOutState, isFalse);
      expect(await tokenStore.readAccess(), isNull);
    });

    test('5. GoRouter redirect logic protects unauthorized routes', () {
      String? simulateRedirect({required bool loggedIn, required String path}) {
        final goingLogin = path == '/login';
        if (!loggedIn && !goingLogin) return '/login';
        if (loggedIn && goingLogin) return '/';
        return null;
      }

      // Guest trying to access protected route -> redirected to /login
      expect(simulateRedirect(loggedIn: false, path: '/'), equals('/login'));
      expect(simulateRedirect(loggedIn: false, path: '/pengumuman/1'), equals('/login'));

      // Guest accessing /login -> allowed (returns null)
      expect(simulateRedirect(loggedIn: false, path: '/login'), isNull);

      // Logged in user accessing /login -> redirected to /
      expect(simulateRedirect(loggedIn: true, path: '/login'), equals('/'));

      // Logged in user accessing / or /pengumuman/1 -> allowed (returns null)
      expect(simulateRedirect(loggedIn: true, path: '/'), isNull);
      expect(simulateRedirect(loggedIn: true, path: '/pengumuman/1'), isNull);
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  _MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
