// test/widget/chat_screen_test.dart
// Widget tests for ChatScreen UI, interactions, and Riverpod state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes_app/ai/ai_provider.dart';
import 'package:notes_app/ai/ai_service.dart';
import 'package:notes_app/features/chat_screen.dart';

class MockAiService extends Mock implements AiService {}

void main() {
  late MockAiService mockAiService;

  setUp(() {
    mockAiService = MockAiService();
    when(() => mockAiService.hasApiKey()).thenAnswer((_) async => true);
    when(() => mockAiService.getApiKey()).thenAnswer((_) async => 'fake-key');
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        aiServiceProvider.overrideWithValue(mockAiService),
      ],
      child: const MaterialApp(
        home: ChatScreen(),
      ),
    );
  }

  testWidgets('ChatScreen menampilkan AppBar, pesan sambutan, dan quick prompts',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Check AppBar
    expect(find.text('AI Asisten Catatan'), findsOneWidget);

    // Check Welcome message
    expect(find.textContaining('Halo! Saya asisten catatan AI Anda'), findsOneWidget);

    // Check Quick prompts
    expect(find.text('💡 Buat ide judul catatan'), findsOneWidget);
    expect(find.text('📝 Ringkas konsep materi'), findsOneWidget);

    // Check Text field & Send button
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('ChatScreen dapat membuka dialog/sheet Pengaturan API Key',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap API Key button in AppBar
    final apiKeyBtn = find.byTooltip('Pengaturan API Key');
    expect(apiKeyBtn, findsOneWidget);
    await tester.tap(apiKeyBtn);
    await tester.pumpAndSettle();

    // Verify modal sheet appears
    expect(find.text('Pengaturan Gemini API Key'), findsOneWidget);
    expect(find.text('Disimpan terenkripsi di FlutterSecureStorage'), findsOneWidget);
    expect(find.text('Tes Koneksi'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
  });

  testWidgets('ChatScreen dapat membersihkan riwayat obrolan',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap Clear Chat button
    final clearBtn = find.byTooltip('Bersihkan Obrolan');
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('Riwayat obrolan telah dibersihkan'), findsOneWidget);
  });

  testWidgets('ChatScreen menampilkan dialog fallback ketika ask gagal',
      (tester) async {
    when(() => mockAiService.ask(any()))
        .thenThrow(AiServiceException('Koneksi internet bermasalah.'));
    when(() => mockAiService.generateOfflineFallback(any()))
        .thenReturn('[Mode Offline Fallback]\nTips ringkasan cepat: ide pokok');

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Enter text and send
    await tester.enterText(find.byType(TextField), 'Ringkas catatan saya');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify Fallback / Busy Dialog appears
    expect(find.text('Layanan AI Sibuk'), findsOneWidget);
    expect(find.text('Mode Offline'), findsOneWidget);

    // Tap "Mode Offline"
    await tester.tap(find.text('Mode Offline'));
    await tester.pumpAndSettle();

    // Verify offline response is displayed in chat
    expect(find.textContaining('[Mode Offline Fallback]'), findsOneWidget);
  });
}
