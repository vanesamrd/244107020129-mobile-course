// test/ai_service_test.dart
// Unit tests for AiService: sanitization, API call parsing, error handling, and offline fallback.

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:notes_app/ai/ai_service.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}
class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockStorage mockStorage;
  late MockHttpClient mockClient;
  late AiService aiService;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockStorage = MockStorage();
    mockClient = MockHttpClient();
    aiService = AiService(
      storage: mockStorage,
      httpClient: mockClient,
    );
  });

  group('Privacy Sanitization Tests', () {
    test('sanitizeInput menyamarkan NIK 16 digit', () {
      const input = 'NIK saya adalah 3507123456780001 untuk verifikasi';
      final sanitized = aiService.sanitizeInput(input);
      expect(sanitized, contains('[NIK DIRAHASIAKAN]'));
      expect(sanitized, isNot(contains('3507123456780001')));
    });

    test('sanitizeInput menyamarkan nomor telepon Indonesia', () {
      const input = 'Hubungi saya di 081234567890 atau +6285298765432';
      final sanitized = aiService.sanitizeInput(input);
      expect(sanitized, contains('[NO TELEPON DIRAHASIAKAN]'));
      expect(sanitized, isNot(contains('081234567890')));
      expect(sanitized, isNot(contains('+6285298765432')));
    });

    test('sanitizeInput menyamarkan alamat email pengguna', () {
      const input = 'Email kampus: mahasiswa@kampus.ac.id mohon dicatat';
      final sanitized = aiService.sanitizeInput(input);
      expect(sanitized, contains('[EMAIL DIRAHASIAKAN]'));
      expect(sanitized, isNot(contains('mahasiswa@kampus.ac.id')));
    });

    test('sanitizeInput mempertahankan teks aman tanpa data sensitif', () {
      const input = 'Tolong buatkan ringkasan materi arsitektur mobile Flutter.';
      final sanitized = aiService.sanitizeInput(input);
      expect(sanitized, equals(input));
    });
  });

  group('API Key & Secure Storage Tests', () {
    test('getApiKey mengembalikan nilai dari storage', () async {
      when(() => mockStorage.read(key: AiService.apiKeyStorageKey))
          .thenAnswer((_) async => 'AIzaSyFakeKey123');

      final key = await aiService.getApiKey();
      expect(key, 'AIzaSyFakeKey123');
      verify(() => mockStorage.read(key: AiService.apiKeyStorageKey)).called(1);
    });

    test('hasApiKey return false saat key kosong atau null', () async {
      when(() => mockStorage.read(key: AiService.apiKeyStorageKey))
          .thenAnswer((_) async => null);

      final hasKey = await aiService.hasApiKey();
      expect(hasKey, isFalse);
    });

    test('saveApiKey menyimpan key terpotong rapi', () async {
      when(() => mockStorage.write(
            key: AiService.apiKeyStorageKey,
            value: 'my-secret-key',
          )).thenAnswer((_) async {});

      await aiService.saveApiKey('  my-secret-key  ');
      verify(() => mockStorage.write(
            key: AiService.apiKeyStorageKey,
            value: 'my-secret-key',
          )).called(1);
    });

    test('deleteApiKey menghapus key dari secure storage', () async {
      when(() => mockStorage.delete(key: AiService.apiKeyStorageKey))
          .thenAnswer((_) async {});

      await aiService.deleteApiKey();
      verify(() => mockStorage.delete(key: AiService.apiKeyStorageKey)).called(1);
    });
  });

  group('ask() Request & Response Handling', () {
    test('ask melemparkan exception jika API Key belum diatur', () async {
      when(() => mockStorage.read(key: AiService.apiKeyStorageKey))
          .thenAnswer((_) async => null);

      expect(
        () => aiService.ask('Apa kabar?'),
        throwsA(isA<AiServiceException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });

    test('ask melemparkan exception jika pertanyaan kosong', () async {
      expect(
        () => aiService.ask('   '),
        throwsA(isA<AiServiceException>()),
      );
    });

    test('ask berhasil mem-parse respons 200 dari Gemini', () async {
      when(() => mockStorage.read(key: AiService.apiKeyStorageKey))
          .thenAnswer((_) async => 'valid-api-key');

      final mockResponseBody = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Ini adalah ringkasan catatan kuliah Anda.'}
              ]
            }
          }
        ]
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(mockResponseBody, 200));

      final response = await aiService.ask('Tolong buat ringkasan');
      expect(response, 'Ini adalah ringkasan catatan kuliah Anda.');
    });

    test('ask menangani status 429 (Rate limit)', () async {
      when(() => mockStorage.read(key: AiService.apiKeyStorageKey))
          .thenAnswer((_) async => 'valid-api-key');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Rate limit exceeded', 429));

      expect(
        () => aiService.ask('Pertanyaan'),
        throwsA(isA<AiServiceException>().having(
          (e) => e.statusCode,
          'statusCode',
          429,
        )),
      );
    });

    test('ask menangani status 500 (Internal Server Error)', () async {
      when(() => mockStorage.read(key: AiService.apiKeyStorageKey))
          .thenAnswer((_) async => 'valid-api-key');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => aiService.ask('Pertanyaan'),
        throwsA(isA<AiServiceException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });
  });

  group('Offline Fallback Tests', () {
    test('generateOfflineFallback memberikan respons relevan untuk ringkasan', () {
      final fallback = aiService.generateOfflineFallback('tolong ringkas catatan ini');
      expect(fallback, contains('[Mode Offline Fallback]'));
      expect(fallback, contains('ringkasan'));
    });

    test('generateOfflineFallback memberikan respons relevan untuk judul', () {
      final fallback = aiService.generateOfflineFallback('beri ide judul');
      expect(fallback, contains('[Mode Offline Fallback]'));
      expect(fallback, contains('judul'));
    });

    test('generateOfflineFallback memberikan respons umum untuk input lain', () {
      final fallback = aiService.generateOfflineFallback('siapa penemu komputer?');
      expect(fallback, contains('[Mode Offline Fallback]'));
      expect(fallback, contains('offline'));
    });
  });
}
