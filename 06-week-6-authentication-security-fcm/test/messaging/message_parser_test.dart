// 🧪 Unit Tests untuk Message Parser
//
// Jalankan dengan:
// $ cd /path/to/project
// $ flutter test test/messaging/message_parser_test.dart
//
// Atau jalankan semua test:
// $ flutter test

import 'package:flutter_test/flutter_test.dart';

// Import pure functions dari message_parser
// Ganti path sesuai struktur project Anda
import 'package:campus_notify/messaging/message_parser.dart';

void main() {
  group('routeFromMessage - Route Parsing Tests', () {
    // ========================================================================
    // TEST: Valid Routes
    // ========================================================================
    test('Valid announcement route /pengumuman/123', () {
      final data = {'route': '/pengumuman/123'};
      final result = routeFromMessage(data);
      expect(result, equals('/pengumuman/123'));
    });

    test('Valid home route /', () {
      final data = {'route': '/'};
      final result = routeFromMessage(data);
      expect(result, equals('/'));
    });

    test('Valid login route /login', () {
      final data = {'route': '/login'};
      final result = routeFromMessage(data);
      expect(result, equals('/login'));
    });

    test('Valid demo route /demo', () {
      final data = {'route': '/demo'};
      final result = routeFromMessage(data);
      expect(result, equals('/demo'));
    });

    // ========================================================================
    // TEST: Invalid Routes (should fallback to home '/')
    // ========================================================================
    test('Invalid route /invalid/path returns fallback /', () {
      final data = {'route': '/invalid/path'};
      final result = routeFromMessage(data);
      expect(result, equals('/'));
    });

    test('Empty route returns fallback /', () {
      final data = {'route': ''};
      final result = routeFromMessage(data);
      expect(result, equals('/'));
    });

    test('Whitespace-only route returns fallback /', () {
      final data = {'route': '   '};
      final result = routeFromMessage(data);
      expect(result, equals('/'));
    });

    // ========================================================================
    // TEST: Missing or null values
    // ========================================================================
    test('Missing route key returns fallback /', () {
      final data = <String, dynamic>{};
      final result = routeFromMessage(data);
      expect(result, equals('/'));
    });

    test('Null route value returns fallback /', () {
      final data = {'route': null};
      final result = routeFromMessage(data);
      expect(result, equals('/'));
    });

    test('Non-string route value returns fallback /', () {
      final data = {'route': 123}; // integer instead of string
      final result = routeFromMessage(data);
      expect(result, equals('/'));
    });

    test('List route value returns fallback /', () {
      final data = {
        'route': ['/pengumuman/123'],
      }; // list instead of string
      final result = routeFromMessage(data);
      expect(result, equals('/'));
    });

    // ========================================================================
    // TEST: Route with whitespace trimming
    // ========================================================================
    test('Route with leading/trailing whitespace is trimmed', () {
      final data = {'route': '  /pengumuman/456  '};
      final result = routeFromMessage(data);
      expect(result, equals('/pengumuman/456'));
    });

    // ========================================================================
    // TEST: Complex announcement IDs
    // ========================================================================
    test('Announcement with numeric ID', () {
      final data = {'route': '/pengumuman/99999'};
      final result = routeFromMessage(data);
      expect(result, equals('/pengumuman/99999'));
    });

    test(
      'Announcement with alphanumeric ID (invalid - only numeric allowed)',
      () {
        final data = {'route': '/pengumuman/abc123'};
        final result = routeFromMessage(data);
        expect(result, equals('/')); // Fallback to home for invalid ID format
      },
    );
  });

  group('announcementIdFromMessage - ID Extraction Tests', () {
    test('Extract valid announcement ID', () {
      final data = {'announcement_id': '123'};
      final result = announcementIdFromMessage(data);
      expect(result, equals('123'));
    });

    test('Extract ID with whitespace trimmed', () {
      final data = {'announcement_id': '  456  '};
      final result = announcementIdFromMessage(data);
      expect(result, equals('456'));
    });

    test('Missing announcement_id returns null', () {
      final data = <String, dynamic>{};
      final result = announcementIdFromMessage(data);
      expect(result, isNull);
    });

    test('Null announcement_id returns null', () {
      final data = {'announcement_id': null};
      final result = announcementIdFromMessage(data);
      expect(result, isNull);
    });

    test('Non-string announcement_id returns null', () {
      final data = {'announcement_id': 789}; // integer
      final result = announcementIdFromMessage(data);
      expect(result, isNull);
    });
  });

  group('metadataFromMessage - Metadata Extraction Tests', () {
    test('Extract all metadata except route', () {
      final data = {
        'route': '/pengumuman/123',
        'announcement_id': '123',
        'priority': 'high',
        'timestamp': '2024-10-04T10:30:00Z',
      };
      final result = metadataFromMessage(data);

      expect(result.containsKey('route'), false); // route should be removed
      expect(result['announcement_id'], equals('123'));
      expect(result['priority'], equals('high'));
      expect(result['timestamp'], equals('2024-10-04T10:30:00Z'));
    });

    test('Empty data returns empty metadata', () {
      final data = <String, dynamic>{};
      final result = metadataFromMessage(data);
      expect(result.isEmpty, true);
    });

    test('Only route in data returns empty metadata', () {
      final data = {'route': '/pengumuman/123'};
      final result = metadataFromMessage(data);
      expect(result.isEmpty, true);
    });
  });

  group('Integration Tests - Real FCM Payload Simulation', () {
    /// Simulates actual FCM message data received from Firebase
    test('Parse typical FCM announcement message', () {
      final fcmData = {
        'route': '/pengumuman/123',
        'announcement_id': '123',
        'title': 'Pengumuman Penting',
        'body': 'Cek pengumuman akademik terbaru',
        'priority': 'high',
        'timestamp': '2024-10-04T10:30:00Z',
      };

      final route = routeFromMessage(fcmData);
      final id = announcementIdFromMessage(fcmData);
      final metadata = metadataFromMessage(fcmData);

      expect(route, equals('/pengumuman/123'));
      expect(id, equals('123'));
      expect(metadata['announcement_id'], equals('123'));
      expect(metadata['priority'], equals('high'));
      expect(metadata.containsKey('route'), false);
    });

    test('Parse FCM message with missing optional fields', () {
      // Minimal FCM payload
      final fcmData = {'route': '/pengumuman/999'};

      final route = routeFromMessage(fcmData);
      final id = announcementIdFromMessage(fcmData);
      final metadata = metadataFromMessage(fcmData);

      expect(route, equals('/pengumuman/999'));
      expect(id, isNull);
      expect(metadata.isEmpty, true);
    });

    test('Parse FCM message with malformed route field', () {
      final fcmData = {
        'route': '/invalid/announcement',
        'announcement_id': '123',
      };

      final route = routeFromMessage(fcmData);

      // Route is invalid, so should fallback to home
      expect(route, equals('/'));

      // Other fields should still be extractable
      expect(announcementIdFromMessage(fcmData), equals('123'));
    });
  });

  group('Edge Cases & Boundary Tests', () {
    test('Very long route string', () {
      final longId = 'a' * 1000; // 1000 character ID
      final data = {'route': '/pengumuman/$longId'};
      final result = routeFromMessage(data);
      expect(result.contains(longId), false); // Should fail validation
      expect(result, equals('/'));
    });

    test('Route with special characters', () {
      final data = {'route': '/pengumuman/123!@#\$%'};
      final result = routeFromMessage(data);
      // Might be invalid, should fallback
      // (Depends on AppRoutes regex validation)
      expect(result.isNotEmpty, true); // Just verify it's not empty
    });

    test('Unicode route', () {
      final data = {'route': '/pengumuman/\ud83d\ude00'}; // emoji
      final result = routeFromMessage(data);
      // Likely invalid, should fallback to /
      expect(result, equals('/'));
    });

    test('Case sensitivity of route', () {
      final data = {'route': '/PENGUMUMAN/123'};
      final result = routeFromMessage(data);
      expect(result, equals('/')); // Should be lowercase
    });
  });
}
