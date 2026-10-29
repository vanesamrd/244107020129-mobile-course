// lib/features/notes/domain/search_notes_use_case.dart
// Pure domain use case – no Flutter/Dio/SQLite imports.
// Owns the single filter rule so widgets never contain business logic.

import 'note.dart';

/// Filters [notes] whose title contains [query] (case-insensitive).
/// Returns an empty list when [query] is blank (no trimming side-effects in UI).
List<Note> filterNotes(List<Note> notes, String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return List.unmodifiable(notes);
  return notes
      .where((n) => n.title.toLowerCase().contains(trimmed))
      .toList(growable: false);
}
