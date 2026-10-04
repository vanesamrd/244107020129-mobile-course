import 'package:dio/dio.dart';
import 'secure_storage_service.dart';

typedef OnLogoutCallback = void Function();

class DioClient {
  late final Dio dio;
  final SecureStorageService secureStorage;
  final OnLogoutCallback onSessionExpired;
  final String baseUrl;

  DioClient({
    required this.secureStorage,
    required this.onSessionExpired,
    this.baseUrl = 'https://api.kampus.ac.id',
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Mencegah request balapan (race condition) dengan QueuedInterceptorsWrapper
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Otomatis lampirkan Authorization Bearer jika token ada
          final token = await secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Menangkap status 401 Unauthorized
          if (error.response?.statusCode == 401) {
            final requestOptions = error.requestOptions;

            // Batasi retry MAKSIMAL 1 KALI saja agar tidak looping
            final isRetry = requestOptions.extra['isRetry'] ?? false;
            if (isRetry) {
              await _handleAutoLogout();
              return handler.reject(error);
            }

            try {
              final refreshToken = await secureStorage.getRefreshToken();
              if (refreshToken == null || refreshToken.isEmpty) {
                await _handleAutoLogout();
                return handler.reject(error);
              }

              // Panggil endpoint refresh token
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final refreshResponse = await refreshDio.post(
                '/api/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              if (refreshResponse.statusCode == 200) {
                final newAccessToken =
                    refreshResponse.data['accessToken'] as String;
                final newRefreshToken =
                    refreshResponse.data['refreshToken'] as String;

                // Simpan token baru ke Secure Storage
                await secureStorage.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                );

                // Tandai bahwa request ini sudah di-retry 1x
                requestOptions.extra['isRetry'] = true;
                requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                // Ulangi request asli
                final retryResponse = await dio.fetch(requestOptions);
                return handler.resolve(retryResponse);
              } else {
                // Refresh token mati atau kedaluwarsa
                await _handleAutoLogout();
                return handler.reject(error);
              }
            } catch (_) {
              // Exception saat refresh: bersihkan sesi & logout otomatis
              await _handleAutoLogout();
              return handler.reject(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _handleAutoLogout() async {
    await secureStorage.clearAll();
    onSessionExpired();
  }
}
