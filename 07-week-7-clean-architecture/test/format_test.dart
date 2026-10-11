import 'package:flutter_test/flutter_test.dart';
import 'package:week_7_clean_architecture/core/format.dart';

void main() {
  group('formatDate', () {
    test('formats DateTime correctly to YYYY-MM-DD', () {
      final date = DateTime(2026, 9, 27);
      expect(formatDate(date), '2026-09-27');
    });

    test('pads single digits with leading zeros', () {
      final date = DateTime(2026, 1, 5);
      expect(formatDate(date), '2026-01-05');
    });
  });

  group('parseRouteId', () {
    test('extracts integer id from route path', () {
      expect(parseRouteId('/notes/123'), 123);
      expect(parseRouteId('announcements/42'), 42);
    });

    test('returns null for invalid or empty path', () {
      expect(parseRouteId('/notes/abc'), isNull);
      expect(parseRouteId(''), isNull);
      expect(parseRouteId('/'), isNull);
    });
  });
}

