import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({this.remoteClient});

  // Contoh dependency remoteClient / httpClient
  final dynamic remoteClient;

  @override
  Future<({List<Announcement> announcements, Failure? failure})> getAnnouncements() async {
    try {
      // Simulasi pengambilan data pengumuman
      final dummyData = <Map<String, dynamic>>[
        {
          'id': '1',
          'title': 'Selamat Datang',
          'content': 'Sistem clean architecture berhasil dikonfigurasi.',
          'published_at': DateTime.now().toIso8601String(),
        },
      ];

      final announcements = dummyData
          .map((item) => AnnouncementModel.fromMap(item).toEntity())
          .toList();

      return (announcements: announcements, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: NetworkFailure('Gagal mengambil pengumuman: $e'),
      );
    }
  }
}

