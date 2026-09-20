import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/comment.dart';
import 'repositories/comment_repository.dart';
import 'providers.dart';

/// Provider repository komentar.
///
/// Dio diambil dari dioProvider yang sudah dibuat
/// pada providers.dart sehingga konfigurasi jaringan
/// tetap terpusat di satu tempat.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) {
    return CommentRepository(
      ref.watch(dioProvider),
    );
  },
);

/// AsyncNotifier untuk mengambil komentar berdasarkan postId.
///
/// Karena menggunakan family pada Riverpod 3,
/// postId diberikan melalui constructor.
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  /// Constructor menerima postId dari family provider.
  CommentNotifier(this.postId);

  /// ID post yang akan digunakan untuk mengambil komentar.
  final int postId;

  @override
  Future<List<Comment>> build() async {
    // Ambil repository melalui Riverpod.
    final repository = ref.watch(commentRepositoryProvider);

    // Jika repository melempar exception,
    // AsyncNotifier otomatis mengubah state menjadi AsyncError.
    return repository.fetchComments(postId);
  }

  /// Mengambil ulang data komentar.
  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(commentRepositoryProvider);

      // Ambil ulang komentar berdasarkan postId.
      state = AsyncData(
        await repository.fetchComments(postId),
      );
    } catch (e, st) {
      // Jika request gagal, ubah state menjadi AsyncError.
      state = AsyncError(e, st);
    }
  }
}

/// Family provider digunakan karena endpoint membutuhkan postId.
///
/// Contoh:
/// ref.watch(commentProvider(1))
///
/// akan mengambil:
/// GET /comments?postId=1
final commentProvider =
    AsyncNotifierProvider.family<CommentNotifier, List<Comment>, int>(
  CommentNotifier.new,
);