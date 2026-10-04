/// 📝 Pure Functions untuk Parsing FCM Message
///
/// File ini berisi fungsi murni (pure functions) untuk parsing RemoteMessage data.
/// Pure function = tidak ada dependency pada Firebase, global state, atau side effects.
/// Keuntungan: Bisa di-unit-test tanpa Firebase mocking!
///
/// Gunakan:
/// ```dart
/// // Dari RemoteMessage (Firebase)
/// final route = routeFromMessage(message.data);
///
/// // Dari Map biasa (untuk testing)
/// final route = routeFromMessage({'route': '/pengumuman/123'});
/// ```
library;

import '../routes.dart';

/// Extract dan validasi route dari FCM message data.
///
/// **Behavior:**
/// 1. Ambil value dari key 'route' di map data
/// 2. Validasi format route (harus valid di AppRoutes)
/// 3. Return route jika valid, fallback ke '/' jika tidak
///
/// **Examples:**
/// ```dart
/// routeFromMessage({'route': '/pengumuman/123'})
///   → '/pengumuman/123'
///
/// routeFromMessage({'route': '/invalid/path'})
///   → '/' (fallback, karena invalid)
///
/// routeFromMessage({})
///   → '/' (fallback, karena tidak ada key 'route')
///
/// routeFromMessage({'route': null})
///   → '/' (fallback, karena null)
/// ```
String routeFromMessage(Map<String, dynamic> data) {
  // 1. Ambil raw value dari key 'route'
  final rawRoute = data['route'];

  // 2. Type check & handle null
  if (rawRoute == null || rawRoute is! String) {
    debugLog('[routeFromMessage] Invalid route type: $rawRoute');
    return '/';
  }

  // 3. Trim whitespace
  final route = rawRoute.trim();

  // 4. Validasi route format
  if (!AppRoutes.isValidRoute(route)) {
    debugLog('[routeFromMessage] Invalid route format: $route');
    return '/';
  }

  // 5. Return valid route
  debugLog('[routeFromMessage] Parsed route: $route');
  return route;
}

/// Extract announcement ID dari data map.
///
/// **Usage:**
/// ```dart
/// final id = announcementIdFromMessage({'announcement_id': '123'});
///   → '123'
///
/// final id = announcementIdFromMessage({});
///   → null
/// ```
String? announcementIdFromMessage(Map<String, dynamic> data) {
  final id = data['announcement_id'];
  if (id == null || id is! String) return null;
  return id.trim();
}

/// Extract all custom metadata dari FCM data payload.
///
/// **Useful untuk tracking, analytics, dll**
/// ```dart
/// final metadata = metadataFromMessage({
///   'route': '/pengumuman/123',
///   'announcement_id': '123',
///   'priority': 'high',
///   'timestamp': '2024-10-04T10:30:00Z',
/// });
///
/// metadata = {
///   'announcement_id': '123',
///   'priority': 'high',
///   'timestamp': '2024-10-04T10:30:00Z',
/// }
/// ```
Map<String, String> metadataFromMessage(Map<String, dynamic> data) {
  return Map<String, String>.from(
    data..remove('route'), // Exclude 'route' key
  );
}

/// Debug log helper (untuk testing & development)
///
/// Di production, bisa replace dengan logging system yang proper.
void debugLog(String message) {
  // ignore: avoid_print
  print(message); // Use print instead of debugPrint untuk testability
}
