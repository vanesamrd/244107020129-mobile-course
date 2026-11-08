// test/notes_screen_search_test.dart
// Integration test for search and clear in NotesScreen without real SQLite.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/notes_repository.dart';
import 'package:notes_app/features/notes/presentation/notes_provider.dart';
import 'package:notes_app/features/notes/presentation/notes_screen.dart';

class _FakeNotesRepository implements NotesRepository {
  _FakeNotesRepository(this._notes);

  final List<Note> _notes;

  @override
  Future<List<Note>> fetchAll() async => List<Note>.unmodifiable(_notes);

  @override
  Future<Note> save(Note note) async => note;

  @override
  Future<void> delete(int id) async {
    _notes.removeWhere((note) => note.id == id);
  }
}

void main() {
  testWidgets('NotesScreen memfilter daftar dan clear mengembalikan semua', (
    tester,
  ) async {
    final notes = [
      Note(
        id: 1,
        title: 'Belanja Mingguan',
        body: 'susu, telur',
        createdAt: DateTime(2025, 1, 1),
      ),
      Note(
        id: 2,
        title: 'Meeting Project Alpha',
        body: 'standup 09.00',
        createdAt: DateTime(2025, 1, 2),
      ),
    ];
    final repository = _FakeNotesRepository(notes);
    final container = ProviderContainer(
      overrides: [notesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belanja Mingguan'), findsOneWidget);
    expect(find.text('Meeting Project Alpha'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search_field')), 'belanja');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Belanja Mingguan'), findsOneWidget);
    expect(find.text('Meeting Project Alpha'), findsNothing);

    await tester.tap(find.byIcon(Icons.cancel_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Belanja Mingguan'), findsOneWidget);
    expect(find.text('Meeting Project Alpha'), findsOneWidget);
  });
}
