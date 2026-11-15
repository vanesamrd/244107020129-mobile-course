import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note_title_validator.dart';

void main() {
  group('isValidNoteTitle', () {
    test('menerima judul yang berisi teks', () {
      expect(isValidNoteTitle('Belajar Flutter'), isTrue);
    });

    test('menerima judul dengan spasi di awal dan akhir', () {
      expect(isValidNoteTitle('  Rangkuman Materi  '), isTrue);
    });

    test('menolak teks kosong atau hanya spasi', () {
      expect(isValidNoteTitle(''), isFalse);
      expect(isValidNoteTitle('   '), isFalse);
      expect(isValidNoteTitle('\n\t'), isFalse);
    });
  });
}
