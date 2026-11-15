import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notes_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pengguna dapat menambah, mencari, dan menghapus catatan', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Catatan Saya'), findsOneWidget);

    final uniqueTitle = 'Catatan Uji ${DateTime.now().millisecondsSinceEpoch}';

    await tester.tap(find.byKey(const Key('add-note-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      uniqueTitle,
    );
    await tester.enterText(
      find.byKey(const Key('note-body-field')),
      'Dibuat oleh integration test Week 12',
    );
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.text(uniqueTitle), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('search_field')),
      'Catatan Uji',
    );
    await tester.pumpAndSettle();

    expect(find.text(uniqueTitle), findsOneWidget);
    expect(find.textContaining('hasil untuk'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search_field')), '');
    await tester.pumpAndSettle();

    await tester.drag(find.text(uniqueTitle), const Offset(-600, 0));
    await tester.pumpAndSettle();

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pumpAndSettle();

    expect(find.text(uniqueTitle), findsNothing);
  });
}
