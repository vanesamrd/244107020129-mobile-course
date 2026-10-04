// 🧪 Auth + Push Integration Tests
//
// Test FCM message parsing + authentication flow tanpa Firebase dependency.
// Semua test menggunakan pure functions dan fake implementations.
//
// Run: `flutter test test/auth_push_test.dart`

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/messaging/message_parser.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';

void main() {
  group('Auth + Push Integration Tests', () {
    // ========================================================================
    // 1. Message Route Parsing
    // ========================================================================
    group('Message Route Parsing', () {
      test('Valid route with announcement ID', () {
        final data = {
          'route': '/pengumuman/12345',
          'title': 'Penting',
          'body': 'Pengumuman baru',
        };

        final route = routeFromMessage(data);
        expect(route, '/pengumuman/12345');
      });

      test('Route dengan whitespace di-trim', () {
        final data = {'route': '  /pengumuman/12345  \n', 'title': 'Penting'};

        final route = routeFromMessage(data);
        expect(route, '/pengumuman/12345');
      });

      test('Missing route returns fallback home route', () {
        final data = {'title': 'Penting', 'body': 'Tanpa route'};

        final route = routeFromMessage(data);
        expect(route, '/'); // Fallback to home
      });

      test('Invalid route format returns fallback home route', () {
        final data = {
          'route': 'invalid-format', // Bukan format path yang valid
          'title': 'Penting',
        };

        final route = routeFromMessage(data);
        expect(route, '/'); // Fallback to home
      });

      test('Empty route returns fallback home route', () {
        final data = {'route': '', 'title': 'Penting'};

        final route = routeFromMessage(data);
        expect(route, '/'); // Fallback to home
      });
    });

    // ========================================================================
    // 2. Message Data Extraction
    // ========================================================================
    group('Message Data Extraction', () {
      test('Extract announcement ID dari message (snake_case key)', () {
        final data = {
          'route': '/pengumuman/98765',
          'announcement_id': '98765',
          'title': 'Update Kampus',
          'body': 'Pengumuman penting',
        };

        final id = announcementIdFromMessage(data);
        expect(id, '98765');
      });

      test('ID dengan whitespace di-trim', () {
        final data = {'announcement_id': '  54321  ', 'title': 'Test'};

        final id = announcementIdFromMessage(data);
        expect(id, '54321');
      });

      test('Missing announcementId returns null', () {
        final data = {'route': '/pengumuman/123', 'title': 'Test'};

        final id = announcementIdFromMessage(data);
        expect(id, isNull);
      });

      test('Extract all metadata except route', () {
        final data = {
          'route': '/pengumuman/123',
          'title': 'Judul',
          'body': 'Isi pesan',
          'announcement_id': '123',
          'priority': 'high',
        };

        final metadata = metadataFromMessage(data);
        expect(metadata.containsKey('route'), false);
        expect(metadata['title'], 'Judul');
        expect(metadata['body'], 'Isi pesan');
        expect(metadata['announcement_id'], '123');
        expect(metadata['priority'], 'high');
      });

      test('Metadata dengan empty data returns empty map', () {
        final data = <String, dynamic>{};
        final metadata = metadataFromMessage(data);
        expect(metadata, isEmpty);
      });
    });

    // ========================================================================
    // 3. Error Handling & Authentication
    // ========================================================================
    group('Authentication Error Handling', () {
      test('401 Unauthorized -> user-friendly message', () {
        final response = Response(
          statusCode: 401,
          data: {},
          requestOptions: RequestOptions(path: ''),
        );
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final message = getErrorMessage(error);
        expect(message, contains('login'));
        expect(message, isNotEmpty);
      });

      test('Network timeout -> informative message', () {
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        );

        final message = getErrorMessage(error);
        expect(
          message.toLowerCase().contains('timeout') ||
              message.toLowerCase().contains('lambat'),
          true,
        );
      });

      test('Offline (no internet) -> clear message', () {
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        );

        final message = getErrorMessage(error);
        expect(message, isNotEmpty);
      });

      test('Server error (500) -> helpful message', () {
        final response = Response(
          statusCode: 500,
          data: {},
          requestOptions: RequestOptions(path: ''),
        );
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final message = getErrorMessage(error);
        expect(message, isNotEmpty);
      });

      test('isAuthenticationError detects 401', () {
        final response = Response(
          statusCode: 401,
          data: {},
          requestOptions: RequestOptions(path: ''),
        );
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          response: response,
          type: DioExceptionType.badResponse,
        );

        expect(isAuthenticationError(error), true);
      });

      test('isNetworkError detects connection timeout', () {
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        );

        expect(isNetworkError(error), true);
      });

      test('isServerError detects 503 Service Unavailable', () {
        final response = Response(
          statusCode: 503,
          data: {},
          requestOptions: RequestOptions(path: ''),
        );
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          response: response,
          type: DioExceptionType.badResponse,
        );

        expect(isServerError(error), true);
      });
    });

    // ========================================================================
    // 4. Fake Token Store (untuk mock persistence)
    // ========================================================================
    group('Fake Token Store', () {
      late FakeTokenStore tokenStore;

      setUp(() {
        tokenStore = FakeTokenStore();
      });

      test('Store dan retrieve access token', () {
        tokenStore.setAccessToken('token_12345');
        expect(tokenStore.getAccessToken(), 'token_12345');
      });

      test('Store dan retrieve refresh token', () {
        tokenStore.setRefreshToken('refresh_67890');
        expect(tokenStore.getRefreshToken(), 'refresh_67890');
      });

      test('Clear token removes both tokens', () {
        tokenStore.setAccessToken('token_123');
        tokenStore.setRefreshToken('refresh_456');

        tokenStore.clear();

        expect(tokenStore.getAccessToken(), isNull);
        expect(tokenStore.getRefreshToken(), isNull);
      });

      test('Check if token exists', () {
        expect(tokenStore.hasToken(), false);

        tokenStore.setAccessToken('token_123');
        expect(tokenStore.hasToken(), true);
      });

      test('User not logged in if no token', () {
        expect(tokenStore.isLoggedIn(), false);
      });

      test('User logged in with valid token', () {
        tokenStore.setAccessToken('valid_token');
        expect(tokenStore.isLoggedIn(), true);
      });
    });

    // ========================================================================
    // 5. Token Refresh Scenario
    // ========================================================================
    group('Token Refresh Flow', () {
      late FakeTokenStore tokenStore;
      late FakeAuthService authService;

      setUp(() {
        tokenStore = FakeTokenStore();
        authService = FakeAuthService(tokenStore);
      });

      test('Refresh token updates access token', () async {
        // Setup: Login first
        await authService.login('valid@test.com', '123456');
        final oldToken = tokenStore.getAccessToken();

        // Action: Refresh token
        final success = await authService.refreshToken();

        // Verify: Token updated successfully
        expect(success, true);
        expect(tokenStore.getAccessToken(), isNotNull);
        expect(tokenStore.getAccessToken(), isNot(oldToken));
      });

      test(
        'Refresh failure on 401 -> clear session and redirect to login',
        () async {
          // Setup: Login and enable refresh failure
          await authService.login('valid@test.com', '123456');
          authService.failRefresh = true;

          // Action: Try refresh (should fail)
          final success = await authService.refreshToken();

          // Verify: Session cleared, needs to login again
          expect(success, false);
          expect(tokenStore.isLoggedIn(), false);
          expect(tokenStore.getAccessToken(), isNull);
        },
      );

      test('Multiple 401 errors -> only refresh once', () async {
        // Setup: Login
        await authService.login('valid@test.com', '123456');

        // Action: Try refresh multiple times
        final attempt1 = await authService.refreshToken();
        final attempt2 = await authService.refreshToken();
        final attempt3 = await authService.refreshToken();

        // Verify: Only 1 refresh allowed (prevent loop)
        expect(attempt1, true); // First refresh succeeds
        expect(
          attempt2,
          false,
        ); // Second refresh fails (already refreshed once)
        expect(attempt3, false); // Third refresh still fails
        expect(authService.refreshAttempts, lessThanOrEqualTo(1));
      });
    });

    // ========================================================================
    // 6. Routes Validation
    // ========================================================================
    group('Route Constants Validation', () {
      test('AppRoutes has required constants', () {
        expect(AppRoutes.login, isNotEmpty);
        expect(AppRoutes.home, isNotEmpty);
        expect(AppRoutes.pushServiceDemo, isNotEmpty);
      });

      test('announcementDetail generates valid path', () {
        final route = AppRoutes.announcementDetail(id: '12345');
        expect(route, '/pengumuman/12345');
      });

      test('isValidRoute accepts valid paths', () {
        expect(AppRoutes.isValidRoute('/pengumuman/12345'), true);
        expect(AppRoutes.isValidRoute('/login'), true);
        expect(AppRoutes.isValidRoute('/'), true); // home
        expect(AppRoutes.isValidRoute('/demo'), true);
      });

      test('isValidRoute rejects invalid paths', () {
        expect(AppRoutes.isValidRoute('invalid'), false);
        expect(AppRoutes.isValidRoute('/unknown/path'), false);
        expect(
          AppRoutes.isValidRoute('/pengumuman/abc'),
          false,
        ); // ID must be numeric
      });
    });

    // ========================================================================
    // 7. Integration: Message -> Route Navigation
    // ========================================================================
    group('Message to Route Navigation', () {
      test('FCM message triggers announcement page navigation', () {
        // Simulate FCM message
        final message = {
          'route': '/pengumuman/99999',
          'title': 'Pengumuman Penting',
          'body': 'Detail lengkap ada di app',
          'announcement_id': '99999',
        };

        final route = routeFromMessage(message);
        final id = announcementIdFromMessage(message);

        expect(route, '/pengumuman/99999');
        expect(id, '99999');
        expect(AppRoutes.isValidRoute(route), true);
      });

      test('FCM message without route defaults to home', () {
        final message = {'title': 'Update Umum', 'body': 'Ada update terbaru'};

        final route = routeFromMessage(message);
        expect(route, '/'); // Falls back to home
      });
    });
  });
}

// ============================================================================
// FAKE IMPLEMENTATIONS (untuk testing tanpa Firebase/Network)
// ============================================================================

/// Fake implementation TokenStore untuk mocking token persistence
class FakeTokenStore {
  String? _accessToken;
  String? _refreshToken;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void setRefreshToken(String token) {
    _refreshToken = token;
  }

  String? getAccessToken() => _accessToken;

  String? getRefreshToken() => _refreshToken;

  bool hasToken() => _accessToken != null;

  bool isLoggedIn() => _accessToken != null && _accessToken!.isNotEmpty;

  void clear() {
    _accessToken = null;
    _refreshToken = null;
  }
}

/// Fake Auth Service untuk simulate login/refresh
class FakeAuthService {
  final FakeTokenStore tokenStore;
  int refreshAttempts = 0;
  bool failRefresh = false;

  FakeAuthService(this.tokenStore);

  /// Simulate login
  Future<bool> login(String email, String password) async {
    if (email == 'valid@test.com' && password == '123456') {
      tokenStore.setAccessToken(
        'fake_access_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      tokenStore.setRefreshToken(
        'fake_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      refreshAttempts = 0;
      return true;
    }
    return false;
  }

  /// Simulate token refresh
  Future<bool> refreshToken() async {
    // Prevent infinite refresh loop
    if (refreshAttempts >= 1) {
      tokenStore.clear();
      return false;
    }

    refreshAttempts++;

    if (failRefresh) {
      tokenStore.clear();
      return false;
    }

    // Simulate successful refresh
    tokenStore.setAccessToken(
      'new_access_token_${DateTime.now().millisecondsSinceEpoch}',
    );
    return true;
  }

  /// Get current user login status
  bool isLoggedIn() => tokenStore.isLoggedIn();
}
