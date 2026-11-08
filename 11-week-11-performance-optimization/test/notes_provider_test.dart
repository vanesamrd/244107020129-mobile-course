// test/notes_provider_test.dart
// Unit tests for local state updates and rollback in NotesNotifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/notes_repository.dart';
import 'package:notes_app/features/notes/presentation/notes_provider.dart';

class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository(List<Note> initialNotes)
    : _notes = List<Note>.of(initialNotes);

  final List<Note> _notes;
  int _nextId = 100;

  int fetchAllCalls = 0;
  int saveCalls = 0;
  int deleteCalls = 0;
  bool failSave = false;
  bool failDelete = false;

  @override
  Future<List<Note>> fetchAll() async {
    fetchAllCalls++;
    return List<Note>.unmodifiable(_notes);
  }

  @override
  Future<Note> save(Note note) async {
    saveCalls++;
    if (failSave) {
      throw Exception('save failed');
    }
    final saved = note.copyWith(id: _nextId++);
    _notes.insert(0, saved);
    return saved;
  }

  @override
  Future<void> delete(int id) async {
    deleteCalls++;
    if (failDelete) {
      throw Exception('delete failed');
    }
    _notes.removeWhere((note) => note.id == id);
  }
}

void main() {
  final existingNote = Note(
    id: 1,
    title: 'Catatan Lama',
    body: 'isi lama',
    createdAt: DateTime(2025, 1, 1),
  );

  ProviderContainer createContainer(FakeNotesRepository repository) {
    final container = ProviderContainer(
      overrides: [notesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('addNote memperbarui state lokal tanpa fetchAll ulang', () async {
    final repository = FakeNotesRepository([existingNote]);
    final container = createContainer(repository);

    await container.read(notesProvider.future);
    expect(repository.fetchAllCalls, 1);

    await container
        .read(notesProvider.notifier)
        .addNote(title: 'Catatan Baru', body: 'isi baru');

    final notes = container.read(notesProvider).valueOrNull!;
    expect(notes, hasLength(2));
    expect(notes.first.title, 'Catatan Baru');
    expect(repository.fetchAllCalls, 1);
    expect(repository.saveCalls, 1);
  });

  test('addNote mempertahankan state sebelumnya saat save gagal', () async {
    final repository = FakeNotesRepository([existingNote])..failSave = true;
    final container = createContainer(repository);

    await container.read(notesProvider.future);

    await expectLater(
      container
          .read(notesProvider.notifier)
          .addNote(title: 'Gagal', body: 'tidak tersimpan'),
      throwsException,
    );

    final notes = container.read(notesProvider).valueOrNull!;
    expect(notes, hasLength(1));
    expect(notes.single.id, existingNote.id);
    expect(repository.fetchAllCalls, 1);
    expect(repository.saveCalls, 1);
  });

  test('deleteNote menghapus state lokal tanpa fetchAll ulang', () async {
    final repository = FakeNotesRepository([existingNote]);
    final container = createContainer(repository);

    await container.read(notesProvider.future);
    expect(repository.fetchAllCalls, 1);

    await container.read(notesProvider.notifier).deleteNote(existingNote.id);

    final notes = container.read(notesProvider).valueOrNull!;
    expect(notes, isEmpty);
    expect(repository.fetchAllCalls, 1);
    expect(repository.deleteCalls, 1);
  });

  test('deleteNote memulihkan state sebelumnya saat delete gagal', () async {
    final repository = FakeNotesRepository([existingNote])..failDelete = true;
    final container = createContainer(repository);

    await container.read(notesProvider.future);

    await expectLater(
      container.read(notesProvider.notifier).deleteNote(existingNote.id),
      throwsException,
    );

    final notes = container.read(notesProvider).valueOrNull!;
    expect(notes, hasLength(1));
    expect(notes.single.id, existingNote.id);
    expect(repository.fetchAllCalls, 1);
    expect(repository.deleteCalls, 1);
  });
}
