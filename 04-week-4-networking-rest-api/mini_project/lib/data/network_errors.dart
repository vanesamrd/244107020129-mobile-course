import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Data tidak ditemukan (404).';
        }
        if (statusCode == 401 || statusCode == 403) {
          return 'Akses ditolak.';
        }
        return 'Server error ($statusCode).';
      default:
        return 'Terjadi kesalahan jaringan.';
    }
  }

  return error.toString();
}
