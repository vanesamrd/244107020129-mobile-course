// test/search_bar_debounce_test.dart
// Widget tests for the debounced search bar and its clear action.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/presentation/notes_provider.dart';
import 'package:notes_app/features/notes/presentation/widgets/search_bar_widget.dart';

void main() {
  Widget buildTestableWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: NoteSearchBar())),
    );
  }

  testWidgets('query hanya diperbarui setelah debounce 250 ms', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestableWidget(container));
    await tester.enterText(find.byType(TextField), 'belanja');

    expect(container.read(searchQueryProvider), '');

    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(searchQueryProvider), '');

    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(searchQueryProvider), 'belanja');
  });

  testWidgets('ikon clear mengosongkan teks dan query', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestableWidget(container));
    await tester.enterText(find.byType(TextField), 'catatan');
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(searchQueryProvider), 'catatan');
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.cancel_rounded));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(container.read(searchQueryProvider), '');
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
  });

  testWidgets('clear dari luar search bar ikut mengosongkan controller', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestableWidget(container));
    await tester.enterText(find.byType(TextField), 'catatan');
    await tester.pump(const Duration(milliseconds: 300));

    container.read(searchQueryProvider.notifier).state = '';
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
  });
}
