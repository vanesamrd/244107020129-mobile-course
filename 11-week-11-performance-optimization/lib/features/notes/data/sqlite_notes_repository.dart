// lib/features/notes/data/sqlite_notes_repository.dart
// Concrete implementation of [NotesRepository] backed by SQLite.
// Data layer only – imports sqflite but NOT Flutter widgets or Dio.

import 'package:sqflite/sqflite.dart';

import '../domain/note.dart';
import '../domain/notes_repository.dart';
import 'app_database.dart';
import 'note_dto.dart';

class SqliteNotesRepository implements NotesRepository {
  SqliteNotesRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  @override
  Future<List<Note>> fetchAll() async {
    final db = await _db.database;
    final rows = await db.query(NoteDto.table, orderBy: 'created_at DESC');
    return rows.map(NoteDto.fromMap).toList(growable: false);
  }

  @override
  Future<Note> save(Note note) async {
    final db = await _db.database;
    final id = await db.insert(
      NoteDto.table,
      NoteDto.toMap(note),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return note.copyWith(id: id);
  }

  @override
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(NoteDto.table, where: 'id = ?', whereArgs: [id]);
  }
}
