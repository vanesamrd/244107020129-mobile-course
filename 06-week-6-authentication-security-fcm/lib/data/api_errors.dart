/// 📡 API Error Handling - User-Friendly Messages
///
/// File ini mengubah DioException (technical) menjadi pesan ramah pengguna.
/// Gunakan di mana saja untuk konsistensi error messages di seluruh app.
///
/// Contoh:
/// ```dart
/// try {
///   await repository.login(email, password);
/// } catch (e) {
///   final message = getErrorMessage(e);
///   showSnackBar(message);  // User-friendly message
/// }
/// ```
library;

import 'package:dio/dio.dart';

/// Representasi error yang ramah pengguna
class AppError {
  final String message;
  final String? code;
  final Exception? originalException;

  AppError({required this.message, this.code, this.originalException});

  @override
  String toString() => message;
}

/// Extract error message yang ramah pengguna dari exception
///
/// Handles:
/// - DioException (network errors, timeouts, 4xx/5xx responses)
/// - Other exceptions (fallback to generic message)
///
/// **Important:** Sensitif terhadap kode error:
/// - 401 → Minta login ulang
/// - 403 → Akses ditolak
/// - 404 → Resource tidak ditemukan
/// - 500+ → Server error
/// - Timeout → Jaringan lambat/terputus
/// - SocketException → Offline
String getErrorMessage(Object exception) {
  // ========================================================================
  // Handle DioException (dari Dio package)
  // ========================================================================
  if (exception is DioException) {
    return _handleDioException(exception);
  }

  // ========================================================================
  // Handle SocketException (internet offline)
  // ========================================================================
  if (exception.toString().contains('SocketException')) {
    return 'Tidak ada koneksi internet. Periksa WiFi atau data seluler.';
  }

  // ========================================================================
  // Fallback: Generic exception
  // ========================================================================
  return 'Terjadi kesalahan. Coba lagi nanti.';
}

/// Internal: Handle DioException dengan detail
String _handleDioException(DioException error) {
  // 1. ERROR TYPE: Request tidak terkirim sama sekali
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return 'Koneksi timeout. Jaringan Anda lambat atau terputus.';

    case DioExceptionType.sendTimeout:
      return 'Pengiriman data timeout. Periksa koneksi internet.';

    case DioExceptionType.receiveTimeout:
      return 'Penerimaan data timeout. Jaringan Anda lambat.';

    case DioExceptionType.badResponse:
      // Response diterima, tapi status code error
      return _handleResponseError(
        error.response?.statusCode,
        error.response?.data,
      );

    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';

    case DioExceptionType.badCertificate:
      return 'Sertifikat keamanan tidak valid. Periksa tanggal/waktu perangkat.';

    case DioExceptionType.connectionError:
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet.';

    case DioExceptionType.unknown:
      return 'Kesalahan tidak diketahui. Coba lagi nanti.';

    default:
      return 'Kesalahan jaringan. Coba lagi nanti.';
  }
}

/// Internal: Handle HTTP response errors (4xx, 5xx)
String _handleResponseError(int? statusCode, dynamic responseData) {
  final data = responseData is Map ? responseData : {};

  switch (statusCode) {
    // ⚠️ CLIENT ERRORS (4xx)
    case 400:
      // Bad Request - input validation error
      final message = data['message'] ?? data['error'];
      if (message != null) {
        return 'Format data tidak valid: $message';
      }
      return 'Data yang dikirim tidak valid. Periksa kembali.';

    case 401:
      // Unauthorized - token expired atau tidak valid
      return 'Sesi Anda telah berakhir. Silakan login kembali.';

    case 403:
      // Forbidden - tidak memiliki akses
      return 'Anda tidak memiliki akses ke resource ini.';

    case 404:
      // Not Found - endpoint atau resource tidak ada
      return 'Data yang dicari tidak ditemukan.';

    case 409:
      // Conflict - biasanya duplicate entry
      return 'Data sudah ada. Gunakan data yang berbeda.';

    case 422:
      // Unprocessable Entity - validation error dengan detail
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final errorList = errors.values.join(', ');
        return 'Data tidak valid: $errorList';
      }
      return 'Data tidak valid. Silakan periksa kembali.';

    // ⚠️ SERVER ERRORS (5xx)
    case 500:
      return 'Server mengalami error. Coba lagi nanti.';

    case 502:
      return 'Gateway error. Server sedang offline.';

    case 503:
      return 'Server sedang maintenance. Coba lagi nanti.';

    // ⚠️ OTHER ERRORS
    default:
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return 'Permintaan gagal (error $statusCode). Periksa data Anda.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'Server error ($statusCode). Coba lagi nanti.';
      }
      return 'Terjadi kesalahan. Coba lagi nanti.';
  }
}

/// Hanya untuk testing: Create AppError dari message
AppError createAppError(String message, {String? code}) {
  return AppError(message: message, code: code);
}

/// Extract error code dari DioException (untuk logging/analytics)
String? getErrorCode(Object exception) {
  if (exception is DioException) {
    return exception.response?.statusCode.toString() ?? 'unknown';
  }
  return null;
}

/// Check apakah error adalah authentication error (401)
bool isAuthenticationError(Object exception) {
  if (exception is DioException) {
    return exception.response?.statusCode == 401;
  }
  return false;
}

/// Check apakah error adalah network error (timeout, offline)
bool isNetworkError(Object exception) {
  if (exception is DioException) {
    return exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.connectionError;
  }
  return exception.toString().contains('SocketException');
}

/// Check apakah error adalah server error (5xx)
bool isServerError(Object exception) {
  if (exception is DioException) {
    final status = exception.response?.statusCode;
    return status != null && status >= 500;
  }
  return false;
}
