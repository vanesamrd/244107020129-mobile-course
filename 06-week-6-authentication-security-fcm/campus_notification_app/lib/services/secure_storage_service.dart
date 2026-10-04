import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';

  /// Menyimpan pasangan Access Token dan Refresh Token
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
    await _storage.write(key: keyRefreshToken, value: refreshToken);
  }

  /// Mengambil Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: keyAccessToken);
  }

  /// Mengambil Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: keyRefreshToken);
  }

  /// Memeriksa apakah sesi login masih ada
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Menghapus seluruh token saat logout
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
