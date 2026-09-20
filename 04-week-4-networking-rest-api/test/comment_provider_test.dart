
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week4_networking_rest_api/data/comment_provider.dart';
import 'package:week4_networking_rest_api/data/models/comment.dart';
import 'package:week4_networking_rest_api/data/repositories/comment_repository.dart';

class FakeCommentRepository extends CommentRepository {
  FakeCommentRepository(this.comments) : super(
    // Repository asli membutuhkan Dio, tetapi pada test
    // method fetchComments akan dioverride.
    Dio(),
  );

  final List<Comment> comments;

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    return comments;
  }
}

void main() {
  test('comment provider berhasil menggunakan fake repository', () async {
    final container = ProviderContainer(
      overrides: [
        commentRepositoryProvider.overrideWithValue(
          FakeCommentRepository([
            const Comment(
              postId: 1,
              id: 1,
              name: 'Test User',
              email: 'test@example.com',
              body: 'Komentar test',
            ),
          ]),
        ),
      ],
    );

    addTearDown(container.dispose);

    final result = await container.read(
      commentProvider(1).future,
    );

    expect(result.length, 1);
    expect(result.first.id, 1);
    expect(result.first.name, 'Test User');
  });
}