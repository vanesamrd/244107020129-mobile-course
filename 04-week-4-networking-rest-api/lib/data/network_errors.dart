import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Silakan coba lagi.';

      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        if (statusCode == 404) {
          return 'Data tidak ditemukan (404).';
        }

        if (statusCode == 401 || statusCode == 403) {
          return 'Anda tidak memiliki akses ke data ini.';
        }

        if (statusCode != null && statusCode >= 500) {
          return 'Terjadi masalah pada server. Silakan coba lagi.';
        }

        return 'Terjadi kesalahan saat mengambil data.';

      default:
        return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
    }
  }

  return 'Terjadi kesalahan yang tidak diketahui.';
}