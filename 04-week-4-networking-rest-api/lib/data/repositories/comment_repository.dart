import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Repository bertugas sebagai pintu masuk data komentar.
///
/// UI tidak boleh memanggil Dio secara langsung.
/// UI/provider akan meminta data melalui repository ini.
class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil komentar berdasarkan postId.
  ///
  /// Endpoint:
  /// GET /comments?postId={id}
  ///
  /// Timeout sudah dipusatkan di api_client.dart melalui
  /// BaseOptions sehingga repository tidak perlu membuat
  /// konfigurasi Dio sendiri.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {
        'postId': postId,
      },
    );

    // Jika response.data null, gunakan list kosong.
    final data = response.data ?? [];

    // Hanya mengambil data yang benar-benar berbentuk
    // Map<String, dynamic>, kemudian mengubahnya menjadi Comment.
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}