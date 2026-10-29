// lib/features/notes/data/app_database.dart
// SQLite helper – data layer only. Version 2 adds color column.

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'note_dto.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'notes.db'),
      version: 2,
      onCreate: (db, _) => db.execute(NoteDto.createTableSql),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add color column to existing DB
          await db.execute(
            'ALTER TABLE ${NoteDto.table} ADD COLUMN color INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
