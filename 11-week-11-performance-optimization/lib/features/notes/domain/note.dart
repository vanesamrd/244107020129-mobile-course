// lib/features/notes/domain/note.dart
// Entity – pure Dart, no Flutter/Dio/SQLite imports

enum NoteColor { purple, blue, green, orange, pink, yellow }

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.color = NoteColor.purple,
  });

  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NoteColor color;

  Note copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? createdAt,
    NoteColor? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Note && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
