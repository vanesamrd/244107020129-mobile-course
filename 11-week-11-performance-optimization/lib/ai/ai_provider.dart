// lib/ai/ai_provider.dart
// Riverpod state management for AI Chat and API Key configuration.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_service.dart';

/// Provider untuk instance singleton AiService.
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

/// Model data untuk pesan obrolan AI.
enum MessageSender { user, ai, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isError = false,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}

/// State untuk Chat AI.
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool hasApiKey;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasApiKey = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool? hasApiKey,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }
}

/// Notifier pengelola obrolan AI.
class ChatNotifier extends StateNotifier<ChatState> {
  final AiService _aiService;

  ChatNotifier(this._aiService) : super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    final hasKey = await _aiService.hasApiKey();
    state = state.copyWith(
      hasApiKey: hasKey,
      messages: [
        ChatMessage(
          id: 'welcome',
          text: 'Halo! Saya asisten catatan AI Anda. Ada yang bisa saya bantu hari ini? '
              'Anda dapat meminta saya merangkum catatan, memberi ide judul, atau menyusun to-do list.',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> refreshApiKeyStatus() async {
    final hasKey = await _aiService.hasApiKey();
    state = state.copyWith(hasApiKey: hasKey);
  }

  /// Mengirim pesan dan menerima respons AI.
  Future<String?> sendMessage(String text, {bool fallbackToOffline = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final responseText = await _aiService.ask(trimmed);

      final aiMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: responseText,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
      return null;
    } catch (e) {
      if (fallbackToOffline) {
        final offlineResponse = _aiService.generateOfflineFallback(trimmed);
        final fallbackMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: offlineResponse,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          messages: [...state.messages, fallbackMsg],
          isLoading: false,
          errorMessage: null,
        );
        return null;
      }

      final errorStr = e.toString();
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorStr,
      );
      return errorStr;
    }
  }

  /// Menggunakan respons fallback offline untuk pesan terakhir pengguna.
  void useOfflineFallbackForLastUserMessage() {
    final now = DateTime.now();
    final lastUserMsg = state.messages.lastWhere(
      (m) => m.sender == MessageSender.user,
      orElse: () => ChatMessage(
        id: 'default',
        text: 'bantuan catatan',
        sender: MessageSender.user,
        timestamp: now,
      ),
    );

    final fallbackText = _aiService.generateOfflineFallback(lastUserMsg.text);
    final fallbackMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: fallbackText,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, fallbackMsg],
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Hapus riwayat pesan obrolan.
  void clearMessages() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Riwayat obrolan telah dibersihkan. Silakan ajukan pertanyaan baru!',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      ],
      errorMessage: null,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return ChatNotifier(aiService);
});
