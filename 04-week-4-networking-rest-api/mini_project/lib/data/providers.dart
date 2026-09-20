import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  bool _isLoadingMore = false;
  int _page = 1;

  @override
  Future<List<Post>> build() async {
    return _loadPage(page: 1, reset: true);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final items = await _loadPage(page: 1, reset: true);
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadNextPage() async {
    if (_isLoadingMore || state.isLoading) return;

    _isLoadingMore = true;
    final currentItems = state.whenOrNull(data: (posts) => posts) ?? const <Post>[];

    try {
      final nextPage = _page + 1;
      final items = await _loadPage(page: nextPage, reset: false);
      state = AsyncData([...currentItems, ...items]);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<List<Post>> _loadPage({
    required int page,
    required bool reset,
  }) async {
    final repository = ref.read(postRepositoryProvider);
    final items = await repository.fetchPosts(page: page, limit: 10);

    if (reset) {
      _page = 1;
    } else {
      _page = page;
    }

    return items;
  }
}

final postListProvider = AsyncNotifierProvider<PostListNotifier, List<Post>>(
  PostListNotifier.new,
);

final postDetailProvider = FutureProvider.family<Post, int>(
  (ref, id) async {
    final cachedPosts = ref.read(postListProvider).whenOrNull(
      data: (posts) => posts,
    );
    final cached = cachedPosts?.firstWhere(
      (post) => post.id == id,
      orElse: () => const Post(userId: 0, id: 0, title: '', body: ''),
    );

    if (cached != null && cached.id == id && cached.id != 0) {
      return cached;
    }

    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPostById(id);
  },
);
