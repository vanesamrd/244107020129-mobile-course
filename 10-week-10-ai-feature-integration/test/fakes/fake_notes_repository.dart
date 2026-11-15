import 'dart:async';

import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/notes_repository.dart';

class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository({
    List<Note> notes = const [],
    this.error,
  }) : _notes = [...notes];

  final List<Note> _notes;
  final Object? error;

  Completer<void>? loadGate;

  int _nextId = 1000;
  int fetchCount = 0;

  final List<Note> savedNotes = [];
  final List<int> deletedIds = [];

  List<Note> get notes => List.unmodifiable(_notes);

  @override
  Future<List<Note>> fetchAll() async {
    fetchCount++;
    final gate = loadGate;
    if (gate != null) await gate.future;
    if (error != null) throw error!;
    return List<Note>.unmodifiable(_notes);
  }

  @override
  Future<Note> save(Note note) async {
    if (error != null) throw error!;
    final saved = note.copyWith(id: note.id == 0 ? _nextId++ : note.id);
    _notes.removeWhere((item) => item.id == saved.id);
    _notes.insert(0, saved);
    savedNotes.add(saved);
    return saved;
  }

  @override
  Future<void> delete(int id) async {
    if (error != null) throw error!;
    deletedIds.add(id);
    _notes.removeWhere((note) => note.id == id);
  }
}
