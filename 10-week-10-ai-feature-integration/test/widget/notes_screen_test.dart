import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/presentation/notes_provider.dart';
import 'package:notes_app/features/notes/presentation/notes_screen.dart';
import 'package:notes_app/features/notes/presentation/widgets/empty_state_widget.dart';

import '../fakes/fake_notes_repository.dart';

void main() {
  final now = DateTime(2025, 1, 1);

  Widget buildApp(FakeNotesRepository repository) {
    return ProviderScope(
      overrides: [notesRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: NotesScreen()),
    );
  }

  group('NotesScreen –', () {
    testWidgets('menampilkan tampilan awal, empty state, dan FAB', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(FakeNotesRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Catatan Saya'), findsOneWidget);
      expect(find.text('0 catatan tersimpan'), findsOneWidget);
      expect(find.byKey(const Key('add-note-fab')), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });

    testWidgets('menampilkan indikator loading saat data dimuat', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repository = FakeNotesRepository()..loadGate = gate;

      await tester.pumpWidget(buildApp(repository));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });

    testWidgets('menampilkan daftar catatan dari repository', (tester) async {
      final repository = FakeNotesRepository(
        notes: [
          Note(
            id: 1,
            title: 'Baca materi',
            body: 'Flutter testing',
            createdAt: now,
          ),
          Note(id: 2, title: 'Belanja', body: 'susu', createdAt: now),
        ],
      );

      await tester.pumpWidget(buildApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Baca materi'), findsOneWidget);
      expect(find.text('Belanja'), findsOneWidget);
      expect(find.text('2 catatan tersimpan'), findsOneWidget);
    });

    testWidgets('menampilkan pesan error ketika repository gagal', (
      tester,
    ) async {
      final repository = FakeNotesRepository(error: Exception('database rusak'));

      await tester.pumpWidget(buildApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Terjadi kesalahan'), findsOneWidget);
      expect(find.textContaining('database rusak'), findsOneWidget);
    });

    testWidgets('tidak menyimpan catatan ketika judul tidak valid', (
      tester,
    ) async {
      final repository = FakeNotesRepository();
      await tester.pumpWidget(buildApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-note-fab')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('note-title-field')), '   ');
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      expect(find.text('Catatan Baru'), findsOneWidget);
      expect(repository.savedNotes, isEmpty);
    });

    testWidgets('menambah catatan melalui FAB dan bottom sheet', (
      tester,
    ) async {
      final repository = FakeNotesRepository();
      await tester.pumpWidget(buildApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-note-fab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('note-title-field')),
        'Baca materi',
      );
      await tester.enterText(
        find.byKey(const Key('note-body-field')),
        'Bab 1 testing',
      );
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      expect(find.text('Baca materi'), findsOneWidget);
      expect(repository.savedNotes.single.title, 'Baca materi');
      expect(repository.savedNotes.single.body, 'Bab 1 testing');
    });

    testWidgets('memfilter catatan melalui kolom pencarian', (tester) async {
      final repository = FakeNotesRepository(
        notes: [
          Note(id: 1, title: 'Baca materi', body: '', createdAt: now),
          Note(id: 2, title: 'Belanja bulanan', body: '', createdAt: now),
        ],
      );

      await tester.pumpWidget(buildApp(repository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('search_field')),
        'belanja',
      );
      await tester.pumpAndSettle();

      expect(find.text('Belanja bulanan'), findsOneWidget);
      expect(find.text('Baca materi'), findsNothing);
      expect(find.text('1 hasil untuk "belanja"'), findsOneWidget);
    });

    testWidgets('menghapus catatan melalui swipe', (tester) async {
      final repository = FakeNotesRepository(
        notes: [
          Note(
            id: 1,
            title: 'Catatan sementara',
            body: 'hapus saya',
            createdAt: now,
          ),
        ],
      );

      await tester.pumpWidget(buildApp(repository));
      await tester.pumpAndSettle();

      await tester.drag(
        find.text('Catatan sementara'),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();

      expect(repository.deletedIds, [1]);
      expect(find.text('Catatan sementara'), findsNothing);
      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });
  });
}
