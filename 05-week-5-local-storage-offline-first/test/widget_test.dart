import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/main.dart';

void main() {
  testWidgets('Aplikasi menampilkan halaman Catatan Offline',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OfflineNotesApp()),
    );
    await tester.pump();
    expect(find.text('Catatan Offline'), findsOneWidget);
  });
}