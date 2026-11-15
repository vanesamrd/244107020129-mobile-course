import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/presentation/notes_provider.dart';

import 'fakes/fake_notes_repository.dart';

void main() {
  final now = DateTime(2025, 1, 1);
  final notes = [
    Note(id: 1, title: 'Baca materi', body: 'Flutter testing', createdAt: now),
    Note(id: 2, title: 'Belanja', body: 'susu', createdAt: now),
  ];

  ProviderContainer createContainer(FakeNotesRepository repository) {
    final container = ProviderContainer(
      overrides: [notesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('NotesNotifier –', () {
    test('memuat data dari repository', () async {
      final repository = FakeNotesRepository(notes: notes);
      final container = createContainer(repository);

      final result = await container.read(notesProvider.future);

      expect(result, notes);
      expect(repository.fetchCount, 1);
    });

    test('meneruskan error repository sebagai AsyncError', () async {
      final repository = FakeNotesRepository(error: Exception('database gagal'));
      final container = createContainer(repository);

      await expectLater(
        container.read(notesProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(container.read(notesProvider), isA<AsyncError<List<Note>>>());
    });

    test('menampilkan AsyncLoading saat repository belum selesai', () async {
      final gate = Completer<void>();
      final repository = FakeNotesRepository(notes: notes)..loadGate = gate;
      final container = createContainer(repository);

      expect(container.read(notesProvider), isA<AsyncLoading<List<Note>>>());

      gate.complete();
      await container.read(notesProvider.future);
      expect(container.read(notesProvider).valueOrNull, notes);
    });

    test('addNote menyimpan judul dan body yang sudah di-trim', () async {
      final repository = FakeNotesRepository();
      final container = createContainer(repository);
      await container.read(notesProvider.future);

      await container
          .read(notesProvider.notifier)
          .addNote(title: '  Baca materi  ', body: '  Bab 1  ');

      expect(repository.savedNotes, hasLength(1));
      expect(repository.savedNotes.single.title, 'Baca materi');
      expect(repository.savedNotes.single.body, 'Bab 1');
      expect(
        container.read(notesProvider).valueOrNull?.single.title,
        'Baca materi',
      );
    });

    test('deleteNote menghapus catatan dan memuat ulang data', () async {
      final repository = FakeNotesRepository(notes: notes);
      final container = createContainer(repository);
      await container.read(notesProvider.future);

      await container.read(notesProvider.notifier).deleteNote(1);

      expect(repository.deletedIds, [1]);
      expect(container.read(notesProvider).valueOrNull, [notes.last]);
    });
  });
}
