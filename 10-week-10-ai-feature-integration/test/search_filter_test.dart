// test/search_filter_test.dart
// Unit tests for the domain use case – NO Flutter dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/search_notes_use_case.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------
  final now = DateTime(2025, 1, 1);
  final notes = [
    Note(id: 1, title: 'Belanja Mingguan', body: 'susu, telur', createdAt: now),
    Note(id: 2, title: 'Belanja Bulanan', body: 'detergen', createdAt: now),
    Note(
      id: 3,
      title: 'Meeting Project Alpha',
      body: 'standup 09.00',
      createdAt: now,
    ),
    Note(id: 4, title: 'Rencana Liburan', body: 'bali', createdAt: now),
  ];

  // ---------------------------------------------------------------------------
  // filterNotes
  // ---------------------------------------------------------------------------
  group('filterNotes –', () {
    test('query kosong mengembalikan semua catatan', () {
      final result = filterNotes(notes, '');
      expect(result, hasLength(4));
    });

    test('query spasi saja mengembalikan semua catatan', () {
      final result = filterNotes(notes, '   ');
      expect(result, hasLength(4));
    });

    // ✅ Bukti wajib: filter abaikan huruf besar/kecil
    test('filter abaikan huruf besar/kecil', () {
      expect(filterNotes(notes, 'belanja'), hasLength(2));
      expect(filterNotes(notes, 'BELANJA'), hasLength(2));
      expect(filterNotes(notes, 'BeLaNjA'), hasLength(2));
    });

    // ✅ Bukti wajib: query tak cocok kembalikan kosong
    test('query tak cocok kembalikan kosong', () {
      expect(filterNotes(notes, 'zzz-tak-ada'), isEmpty);
    });

    test('partial match pada tengah kata', () {
      final result = filterNotes(notes, 'project');
      expect(result, hasLength(1));
      expect(result.first.id, 3);
    });

    test('filter hanya cocokkan judul, bukan isi (body)', () {
      // 'bali' ada di body note 4, bukan di title → harus kosong
      final result = filterNotes(notes, 'bali');
      expect(result, isEmpty);
    });

    test('query satu karakter cocok beberapa judul', () {
      // 'a' ada di 'Belanja', 'Belanja', 'Alpha', 'Rencana Liburan'
      final result = filterNotes(notes, 'a');
      expect(result.length, greaterThanOrEqualTo(2));
    });
  });
}
