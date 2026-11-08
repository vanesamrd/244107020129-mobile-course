// lib/ai/ai_service.dart
// Service layer for interacting with Google Gemini AI API securely.

import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AiServiceException implements Exception {
  final String message;
  final int? statusCode;

  AiServiceException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String model;

  static const String defaultModel = 'gemini-1.5-flash';
  static const String apiKeyStorageKey = 'ai_api_key';

  AiService({
    FlutterSecureStorage? storage,
    http.Client? httpClient,
    this.model = defaultModel,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = httpClient ?? http.Client();

  String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  /// Default system persona for the campus & notes assistant.
  static const String defaultSystemPrompt =
      'Kamu adalah asisten catatan dan belajar ramah untuk mahasiswa. '
      'Jawab dalam Bahasa Indonesia yang santun, jelas, dan ringkas (maksimal 2-3 paragraf atau poin-poin). '
      'Jangan pernah meminta atau membocorkan data pribadi.';

  /// Membaca API key dari FlutterSecureStorage.
  Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: apiKeyStorageKey);
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan API key ke FlutterSecureStorage.
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: apiKeyStorageKey, value: key.trim());
  }

  /// Menghapus API key dari FlutterSecureStorage.
  Future<void> deleteApiKey() async {
    await _storage.delete(key: apiKeyStorageKey);
  }

  /// Cek apakah API key sudah tersedia.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Sanitasi input untuk melindungi privasi pengguna.
  /// Menghapus / menyamarkan NIK, nomor telepon, dan email sebelum dikirim ke AI API.
  String sanitizeInput(String input) {
    var sanitized = input;

    // Mask NIK (16 digit angka)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b\d{16}\b'),
      (match) => '[NIK DIRAHASIAKAN]',
    );

    // Mask Nomor Telepon Indonesia (misal: 08xx, +62xx, 62xx dengan 10-13 digit)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(\+?62|0)8[1-9][0-9]{7,10}\b'),
      (match) => '[NO TELEPON DIRAHASIAKAN]',
    );

    // Mask Alamat Email
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      (match) => '[EMAIL DIRAHASIAKAN]',
    );

    return sanitized;
  }

  /// Mengirim pertanyaan ke Google Gemini API.
  Future<String> ask(
    String question, {
    String systemPrompt = defaultSystemPrompt,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      throw AiServiceException('Pertanyaan tidak boleh kosong.');
    }

    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw AiServiceException(
        'API key belum diatur. Silakan atur Google Gemini API key di menu Pengaturan AI.',
        401,
      );
    }

    // Melindungi privasi dengan sanitasi input
    final safeQuestion = sanitizeInput(trimmed);

    final uri = Uri.parse('$_apiUrl?key=$apiKey');

    final requestBody = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': safeQuestion}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 800,
      }
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
        return 'Maaf, AI tidak menghasilkan respons. Silakan coba kembali.';
      } else if (response.statusCode == 400) {
        throw AiServiceException(
          'Permintaan tidak valid (400). Periksa format request atau model API.',
          400,
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AiServiceException(
          'API Key tidak valid atau tidak memiliki izin akses (403/401). Periksa kembali API Key Anda.',
          response.statusCode,
        );
      } else if (response.statusCode == 429) {
        throw AiServiceException(
          'Batas kuota (Rate limit) terlampaui (429). Mohon tunggu beberapa saat sebelum mencoba lagi.',
          429,
        );
      } else if (response.statusCode >= 500) {
        throw AiServiceException(
          'Server Gemini AI sedang bermasalah (${response.statusCode}). Silakan coba beberapa saat lagi.',
          response.statusCode,
        );
      } else {
        throw AiServiceException(
          'Gagal memanggil AI API: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw AiServiceException('Koneksi ke AI API habis waktu (timeout). Periksa jaringan internet Anda.');
    } on http.ClientException catch (e) {
      throw AiServiceException('Kendala jaringan: ${e.message}. Pastikan perangkat terhubung internet.');
    } on AiServiceException {
      rethrow;
    } catch (e) {
      throw AiServiceException('Terjadi kesalahan saat memproses respons AI: $e');
    }
  }

  /// Generator respons fallback lokal saat offline atau jika API error.
  String generateOfflineFallback(String question) {
    final lower = question.toLowerCase();
    if (lower.contains('ringkas') || lower.contains('rangkum')) {
      return '📌 [Mode Offline Fallback]\n'
          'Tips ringkasan cepat:\n'
          '1. Tentukan ide pokok tiap paragraf.\n'
          '2. Catat kata kunci utama & poin penting.\n'
          '3. Gunakan bullet point agar mudah dibaca kembali.';
    } else if (lower.contains('judul') || lower.contains('ide')) {
      return '💡 [Mode Offline Fallback]\n'
          'Ide judul catatan:\n'
          '- Ringkasan Materi: Inti Pokok Pembahasan\n'
          '- Catatan Refleksi & Action Plan Mingguan\n'
          '- Quick Reference & Cheat Sheet';
    } else if (lower.contains('jadwal') || lower.contains('to-do') || lower.contains('tugas')) {
      return '📅 [Mode Offline Fallback]\n'
          'Format to-do list efektif:\n'
          '- [ ] Prioritas Utama (High Urgency & Impact)\n'
          '- [ ] Tugas Rutin / Review Catatan\n'
          '- [ ] Rencana Tindak Lanjut Besok';
    } else {
      return '🤖 [Mode Offline Fallback]\n'
          'Layanan AI sedang offline atau tidak dapat dihubungi.\n'
          'Catatan Anda tersimpan aman di database lokal SQLite perangkat.';
    }
  }
}
