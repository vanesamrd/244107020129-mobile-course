import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

Future<Database> openNotesDb() async {
  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, 'notes.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
}
