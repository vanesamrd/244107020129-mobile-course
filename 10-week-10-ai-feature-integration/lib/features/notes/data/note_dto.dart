// lib/features/notes/data/note_dto.dart
// Data-layer DTO – converts between SQLite row maps and domain entities.

import '../domain/note.dart';

class NoteDto {
  static const table = 'notes';

  static Map<String, dynamic> toMap(Note note) => {
    if (note.id != 0) 'id': note.id,
    'title': note.title,
    'body': note.body,
    'created_at': note.createdAt.toIso8601String(),
    'color': note.color.index,
  };

  static Note fromMap(Map<String, dynamic> map) => Note(
    id: map['id'] as int,
    title: map['title'] as String,
    body: map['body'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    color:
        NoteColor.values[(map['color'] as int? ?? 0).clamp(
          0,
          NoteColor.values.length - 1,
        )],
  );

  static const createTableSql =
      '''
    CREATE TABLE IF NOT EXISTS $table (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      title      TEXT    NOT NULL,
      body       TEXT    NOT NULL,
      created_at TEXT    NOT NULL,
      color      INTEGER NOT NULL DEFAULT 0
    )
  ''';
}
