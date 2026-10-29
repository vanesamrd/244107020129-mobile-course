// lib/features/notes/presentation/notes_provider.dart
// Riverpod providers – presentation layer only knows the domain contract.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sqlite_notes_repository.dart';
import '../domain/note.dart';
import '../domain/notes_repository.dart';
import '../domain/search_notes_use_case.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => SqliteNotesRepository(),
);

// ---------------------------------------------------------------------------
// Notes list notifier
// ---------------------------------------------------------------------------

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    return ref.read(notesRepositoryProvider).fetchAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notesRepositoryProvider).fetchAll(),
    );
  }

  Future<void> addNote({
    required String title,
    required String body,
    NoteColor color = NoteColor.purple,
  }) async {
    final note = Note(
      id: 0,
      title: title.trim(),
      body: body.trim(),
      createdAt: DateTime.now(),
      color: color,
    );
    await ref.read(notesRepositoryProvider).save(note);
    await reload();
  }

  Future<void> deleteNote(int id) async {
    await ref.read(notesRepositoryProvider).delete(id);
    await reload();
  }
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

// ---------------------------------------------------------------------------
// Search query provider
// ---------------------------------------------------------------------------

final searchQueryProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// Filtered notes provider (domain use case applied here, not in widget)
// ---------------------------------------------------------------------------

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  return notesAsync.whenData((notes) => filterNotes(notes, query));
});
