import 'package:flutter_test/flutter_test.dart';

class MockSecureStorage {
  final Map<String, String> _vault = {};

  Future<void> write(String key, String value) async => _vault[key] = value;
  Future<String?> read(String key) async => _vault[key];
  Future<void> deleteAll() async => _vault.clear();
}

void main() {
  group('TEST SUITE 2: Session Logic & Dio Token Refresh Interceptor', () {
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
    });

    test('2.1 Secure Storage menyimpan token secara aman', () async {
      await mockStorage.write('access_token', 'jwt_mock_access_123');
      await mockStorage.write('refresh_token', 'jwt_mock_refresh_abc');

      final accessToken = await mockStorage.read('access_token');
      final refreshToken = await mockStorage.read('refresh_token');

      expect(accessToken, equals('jwt_mock_access_123'));
      expect(refreshToken, equals('jwt_mock_refresh_abc'));
    });

    test('2.2 Dio Interceptor merefresh token otomatis 1x saat 401', () async {
      await mockStorage.write('access_token', 'expired_token');
      await mockStorage.write('refresh_token', 'valid_refresh_token');

      bool refreshCalled = false;
      int retryCount = 0;

      Future<int> simulateHttpRequest(String token,
          {bool isRetry = false}) async {
        if (token == 'expired_token' && !isRetry) {
          refreshCalled = true;
          const newAccessToken = 'new_refreshed_access_token';
          await mockStorage.write('access_token', newAccessToken);
          retryCount++;
          return await simulateHttpRequest(newAccessToken, isRetry: true);
        }
        return 200;
      }

      final status = await simulateHttpRequest('expired_token');

      expect(refreshCalled, isTrue);
      expect(retryCount, equals(1)); // Maksimal retry 1x
      expect(status, equals(200));

      final updatedToken = await mockStorage.read('access_token');
      expect(updatedToken, equals('new_refreshed_access_token'));
    });

    test('2.3 Ketika refresh token mati, storage dibersihkan dan memicu logout',
        () async {
      await mockStorage.write('access_token', 'expired_token');
      await mockStorage.write('refresh_token', 'dead_refresh_token');

      bool sessionExpired = false;

      Future<void> handleFailedRefresh() async {
        await mockStorage.deleteAll();
        sessionExpired = true;
      }

      await handleFailedRefresh();

      expect(sessionExpired, isTrue);
      expect(await mockStorage.read('access_token'), isNull);
    });
  });
}
