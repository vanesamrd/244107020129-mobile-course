import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> parseRoute(String path) {
  final uri = Uri.parse(path);
  final segments = uri.pathSegments;

  String? announcementId;
  bool isAnnouncementRoute = false;

  if (segments.length >= 2 && segments[0] == 'pengumuman') {
    announcementId = segments[1];
    isAnnouncementRoute = true;
  }

  return {
    'announcementId': announcementId,
    'isValidAnnouncementRoute': isAnnouncementRoute,
  };
}

String? extractRouteFromFcmData(Map<String, dynamic> data) {
  if (data.containsKey('route') &&
      data['route'] != null &&
      data['route'].toString().isNotEmpty) {
    return data['route'].toString();
  }
  if (data.containsKey('id') &&
      data['id'] != null &&
      data['id'].toString().isNotEmpty) {
    return '/pengumuman/${data['id']}';
  }
  return null;
}

void main() {
  group('TEST SUITE 1: Route Parsing & FCM Deep Link Resolution', () {
    test('1.1 Memvalidasi dan mengekstrak id dari /pengumuman/:id', () {
      final parsed = parseRoute('/pengumuman/krs-ganjil-2026');

      expect(parsed['isValidAnnouncementRoute'], isTrue);
      expect(parsed['announcementId'], equals('krs-ganjil-2026'));
    });

    test('1.2 Mengekstrak rute deep link dari FCM menggunakan data.route', () {
      final fcmPayload = {
        'route': '/pengumuman/krs-ganjil-2026',
        'id': 'krs-ganjil-2026',
      };

      final targetRoute = extractRouteFromFcmData(fcmPayload);
      expect(targetRoute, equals('/pengumuman/krs-ganjil-2026'));
    });

    test('1.3 Mengekstrak rute fallback jika hanya ada data.id', () {
      final fcmPayload = {
        'id': 'beasiswa-prestasi-2026',
      };

      final targetRoute = extractRouteFromFcmData(fcmPayload);
      expect(targetRoute, equals('/pengumuman/beasiswa-prestasi-2026'));
    });
  });
}
