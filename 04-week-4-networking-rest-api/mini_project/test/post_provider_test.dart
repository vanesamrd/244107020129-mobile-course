import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project/data/models/post.dart';
import 'package:mini_project/data/providers.dart';
import 'package:mini_project/data/repositories/post_repository.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository() : super(Dio());

  @override
  Future<List<Post>> fetchPosts({required int page, int limit = 10}) async {
    if (page == 1) {
      return [
        const Post(userId: 1, id: 1, title: 'Title 1', body: 'Body 1'),
        const Post(userId: 1, id: 2, title: 'Title 2', body: 'Body 2'),
      ];
    }
    return [];
  }
}

void main() {
  test('provider should load posts from fake repository', () async {
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(FakePostRepository()),
      ],
    );

    addTearDown(container.dispose);

    final value = await container.read(postListProvider.future);

    expect(value.length, 2);
    expect(value.first.title, 'Title 1');
  });
}
