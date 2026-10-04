/// 🛣️ Centralized Route Definitions
///
/// File ini mengatur semua rute aplikasi (GoRouter) dan deep links (FCM).
/// Tujuan: Hindari hard-coded strings, konsistensi di seluruh aplikasi.
///
/// Gunakan:
/// ```dart
/// // Navigasi ke home
/// context.go(AppRoutes.home);
///
/// // Navigasi ke detail pengumuman
/// context.go(AppRoutes.announcementDetail(id: '123'));
///
/// // FCM deep link
/// {"data": {"route": AppRoutes.announcementDetail(id: '5')}}
/// ```
library;

abstract class AppRoutes {
  // ============================================================================
  // ROOT ROUTES
  // ============================================================================

  /// Halaman login - untuk user yang belum login
  static const String login = '/login';

  /// Halaman home - menampilkan list pengumuman
  static const String home = '/';

  /// Halaman demo PushService - untuk testing notifikasi
  static const String pushServiceDemo = '/demo';

  // ============================================================================
  // PARAMETERIZED ROUTES
  // ============================================================================

  /// Path template untuk detail pengumuman
  ///
  /// Contoh: `/pengumuman/:id`
  static const String _announcementPath = '/pengumuman/:id';

  /// Generate rute detail pengumuman dengan ID tertentu
  ///
  /// ```dart
  /// // Gunakan di GoRouter path
  /// path: AppRoutes.announcementPathTemplate,
  ///
  /// // Gunakan untuk navigasi
  /// context.go(AppRoutes.announcementDetail(id: '123'));
  ///
  /// // Gunakan di FCM data
  /// {"route": AppRoutes.announcementDetail(id: announcement.id)}
  /// ```
  static String announcementDetail({required String id}) => '/pengumuman/$id';

  /// Ambil template path untuk GoRouter route definition
  static const String announcementPathTemplate = _announcementPath;

  /// Extract ID dari path announcement
  ///
  /// ```dart
  /// // Di GoRouter builder
  /// announementId = AppRoutes.extractAnnouncementId(state.pathParameters);
  /// ```
  static String? extractAnnouncementId(Map<String, String> params) {
    return params['id'];
  }

  // ============================================================================
  // VERIFICATION HELPERS
  // ============================================================================

  /// Check apakah path adalah rute login
  static bool isLoginRoute(String path) => path == login;

  /// Check apakah path adalah rute home
  static bool isHomeRoute(String path) => path == home;

  /// Check apakah path adalah rute announcement detail
  static bool isAnnouncementRoute(String path) =>
      RegExp(r'^/pengumuman/\d+$').hasMatch(path);

  /// Check apakah path adalah demo route
  static bool isDemoRoute(String path) => path == pushServiceDemo;

  // ============================================================================
  // ROUTE VALIDATION
  // ============================================================================

  /// Validasi apakah rute FCM valid untuk deep link
  ///
  /// Jangan kirim rute arbitrary dari FCM - hanya rute yang terdaftar di sini.
  static bool isValidRoute(String route) {
    return isLoginRoute(route) ||
        isHomeRoute(route) ||
        isAnnouncementRoute(route) ||
        isDemoRoute(route);
  }

  // ============================================================================
  // FCM TOPIC & MESSAGE FORMAT
  // ============================================================================

  /// Topic untuk broadcast pengumuman kampus
  ///
  /// Semua mahasiswa subscribe topik ini.
  /// Backend kirim: FCM Server API → Topic "pengumuman-kampus"
  static const String campusTopic = 'pengumuman-kampus';

  /// Expected FCM message format:
  /// ```json
  /// {
  ///   "to": "/topics/pengumuman-kampus",
  ///   "notification": {
  ///     "title": "Pengumuman Akademik",
  ///     "body": "Lihat pengumuman terbaru"
  ///   },
  ///   "data": {
  ///     "route": "/pengumuman/123"
  ///   }
  /// }
  /// ```
}
