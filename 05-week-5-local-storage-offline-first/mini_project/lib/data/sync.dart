import 'dart:async';
import 'repositories/note_repository.dart';

Future<List<Map<String, Object?>>> loadPostsCacheFirst({
  required Future<List<Map<String, Object?>>> Function() readCachedPosts,
  required Future<void> Function() refreshPostsInBackground,
}) async {
  final cached = await readCachedPosts();
  unawaited(refreshPostsInBackground());
  return cached;
}

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}