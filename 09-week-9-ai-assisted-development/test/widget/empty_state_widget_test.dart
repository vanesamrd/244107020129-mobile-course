// test/widget/empty_state_widget_test.dart
// Widget test for EmptyStateWidget – no DB/network needed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/search_notes_use_case.dart';
import 'package:notes_app/features/notes/presentation/widgets/empty_state_widget.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Pure widget rendering tests
  // ---------------------------------------------------------------------------
  group('EmptyStateWidget –', () {
    testWidgets('tampil saat tidak ada catatan sama sekali', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyStateWidget(query: '')),
        ),
      );
      expect(find.byKey(const Key('empty_state')), findsOneWidget);
      expect(
        find.text(
          'Tap tombol + Tambah Catatan\nuntuk membuat catatan pertamamu!',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tampil pesan yang tepat saat query tidak cocok', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyStateWidget(query: 'xyz-tidak-ada')),
        ),
      );
      expect(find.byKey(const Key('empty_state')), findsOneWidget);
      expect(find.textContaining('xyz-tidak-ada'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Domain use case integration (pure Dart – no timers/widgets)
  // ---------------------------------------------------------------------------
  group('filteredNotesProvider empty state integration –', () {
    final now = DateTime(2025, 1, 1);
    final notes = [Note(id: 1, title: 'Belanja', body: 'susu', createdAt: now)];

    test(
      'filterNotes kembalikan kosong saat query tidak match → empty state',
      () {
        // Simulasi what filteredNotesProvider does:
        // watch(notesProvider).whenData(notes => filterNotes(notes, query))
        final filtered = filterNotes(notes, 'zzz');
        expect(
          filtered,
          isEmpty,
          reason: 'Empty list triggers EmptyStateWidget',
        );
      },
    );

    test('filterNotes kembalikan semua saat query kosong → list tampil', () {
      final filtered = filterNotes(notes, '');
      expect(filtered, hasLength(1));
    });
  });
}
