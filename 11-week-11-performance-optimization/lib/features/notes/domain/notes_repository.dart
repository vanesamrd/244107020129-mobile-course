// lib/features/notes/domain/notes_repository.dart
// Contract – pure Dart, no Flutter/Dio/SQLite imports

import 'note.dart';

abstract interface class NotesRepository {
  /// Returns all notes ordered by createdAt DESC.
  Future<List<Note>> fetchAll();

  /// Persists [note] and returns the saved entity with its assigned [id].
  Future<Note> save(Note note);

  /// Deletes the note with [id].
  Future<void> delete(int id);
}
