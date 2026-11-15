import 'package:flutter_test/flutter_test.dart';
import 'package:week12_testing/main.dart';

void main() {
  testWidgets('menampilkan ringkasan hasil pengujian Week 12', (tester) async {
    await tester.pumpWidget(const Week12TestingApp());

    expect(find.text('Week 12 – Testing & QA'), findsOneWidget);
    expect(
      find.text('Pengujian dilaksanakan pada project Week 10'),
      findsOneWidget,
    );
    expect(find.text('Coverage: 78,5% (694/884 baris)'), findsOneWidget);
  });
}
