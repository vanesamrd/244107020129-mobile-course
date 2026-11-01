// lib/features/chat_screen.dart
// Interactive AI Chat Screen with streaming/typing indicator, API Key management, and offline fallback.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_provider.dart';
import 'notes/domain/note.dart';
import 'notes/presentation/notes_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _quickPrompts = [
    '💡 Buat ide judul catatan',
    '📝 Ringkas konsep materi',
    '📅 Buat to-do list belajar',
    '✨ Tips produktivitas kuliah',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend({String? customText}) async {
    final query = customText ?? _textController.text.trim();
    if (query.isEmpty) return;

    if (customText == null) {
      _textController.clear();
    }
    _scrollToBottom();

    final error = await ref.read(chatProvider.notifier).sendMessage(query);
    _scrollToBottom();

    if (error != null && mounted) {
      _showErrorFallbackDialog(error);
    }
  }

  void _showErrorFallbackDialog(String errorMessage) {
    final isKeyMissing = errorMessage.contains('API key belum diatur') ||
        errorMessage.contains('401') ||
        errorMessage.contains('403');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: Icon(
          isKeyMissing ? Icons.key_rounded : Icons.cloud_off_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 36,
        ),
        title: Text(isKeyMissing ? 'API Key Belum Diatur' : 'Layanan AI Sibuk'),
        content: Text(
          isKeyMissing
              ? 'Anda belum mengatur Google Gemini API Key. Atur API Key di pengaturan atau gunakan mode respons offline.'
              : 'Gagal terhubung ke AI API: $errorMessage\n\nCoba lagi nanti atau gunakan mode offline.',
        ),
        actions: [
          if (isKeyMissing)
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _showApiKeySettingsSheet();
              },
              child: const Text('Atur API Key'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(chatProvider.notifier)
                  .useOfflineFallbackForLastUserMessage();
              _scrollToBottom();
            },
            child: const Text('Mode Offline'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _showApiKeySettingsSheet() async {
    final aiService = ref.read(aiServiceProvider);
    final currentKey = await aiService.getApiKey() ?? '';
    final keyController = TextEditingController(text: currentKey);
    bool isObscured = true;
    bool isTesting = false;
    String? statusMessage;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (sheetInnerCtx, setSheetState) {
            final cs = Theme.of(sheetInnerCtx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(sheetInnerCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.vpn_key_rounded, color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengaturan Gemini API Key',
                              style: Theme.of(sheetInnerCtx).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Disimpan terenkripsi di FlutterSecureStorage',
                              style: Theme.of(sheetInnerCtx).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keyController,
                    obscureText: isObscured,
                    decoration: InputDecoration(
                      labelText: 'Google Gemini API Key',
                      hintText: 'AIzaSy...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.security_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setSheetState(() => isObscured = !isObscured);
                        },
                      ),
                    ),
                  ),
                  if (statusMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      statusMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusMessage!.contains('Berhasil')
                            ? Colors.green
                            : cs.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  final key = keyController.text.trim();
                                  if (key.isEmpty) {
                                    setSheetState(() {
                                      statusMessage = 'API Key tidak boleh kosong.';
                                    });
                                    return;
                                  }
                                  setSheetState(() {
                                    isTesting = true;
                                    statusMessage = 'Menguji koneksi ke Gemini API...';
                                  });
                                  try {
                                    await aiService.saveApiKey(key);
                                    await aiService.ask('Halo');
                                    setSheetState(() {
                                      isTesting = false;
                                      statusMessage = 'Berhasil! Koneksi API valid.';
                                    });
                                    ref.read(chatProvider.notifier).refreshApiKeyStatus();
                                  } catch (e) {
                                    setSheetState(() {
                                      isTesting = false;
                                      statusMessage = 'Uji gagal: $e';
                                    });
                                  }
                                },
                          icon: isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check_rounded),
                          label: const Text('Tes Koneksi'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final key = keyController.text.trim();
                            if (key.isEmpty) {
                              await aiService.deleteApiKey();
                            } else {
                              await aiService.saveApiKey(key);
                            }
                            await ref
                                .read(chatProvider.notifier)
                                .refreshApiKeyStatus();
                            if (bottomSheetCtx.mounted) {
                              Navigator.of(bottomSheetCtx).pop();
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('API Key berhasil disimpan di Secure Storage.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveMessageAsNote(String text) {
    final firstLine = text.split('\n').first.replaceAll(RegExp(r'[#*_-]'), '').trim();
    final title = firstLine.isNotEmpty
        ? (firstLine.length > 40 ? '${firstLine.substring(0, 40)}...' : firstLine)
        : 'Catatan dari AI';

    ref.read(notesProvider.notifier).addNote(
          title: title,
          body: text,
          color: NoteColor.purple,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Disimpan ke Catatan Saya!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.onPrimary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Asisten Catatan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  chatState.hasApiKey
                      ? '● Gemini AI Siap'
                      : '○ API Key Belum Disetel',
                  style: TextStyle(
                    fontSize: 11,
                    color: chatState.hasApiKey
                        ? Colors.greenAccent
                        : cs.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded),
            tooltip: 'Pengaturan API Key',
            onPressed: _showApiKeySettingsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Bersihkan Obrolan',
            onPressed: () => ref.read(chatProvider.notifier).clearMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages List ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length && chatState.isLoading) {
                  return const _AiLoadingBubble();
                }

                final msg = chatState.messages[index];
                return _ChatBubble(
                  message: msg,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teks disalin ke clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  onSaveAsNote: msg.sender == MessageSender.ai
                      ? () => _saveMessageAsNote(msg.text)
                      : null,
                );
              },
            ),
          ),

          // ── Quick Prompt Chips ────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  backgroundColor: cs.surfaceContainerHigh,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: chatState.isLoading
                      ? null
                      : () => _handleSend(customText: prompt.substring(2).trim()),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Input Bar ─────────────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu ke AI asisten...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: chatState.isLoading ? null : () => _handleSend(),
                    icon: chatState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble Widget ────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.onCopy,
    this.onSaveAsNote,
  });

  final ChatMessage message;
  final VoidCallback onCopy;
  final VoidCallback? onSaveAsNote;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser ? cs.onPrimary : cs.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: onCopy,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: isUser
                                ? cs.onPrimary.withValues(alpha: 0.7)
                                : cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      if (onSaveAsNote != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onSaveAsNote,
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark_add_outlined,
                                size: 14,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Simpan Catatan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.tertiaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 16,
                color: cs.onTertiaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing / Loading Indicator Bubble ─────────────────────────────────────────
class _AiLoadingBubble extends StatefulWidget {
  const _AiLoadingBubble();

  @override
  State<_AiLoadingBubble> createState() => _AiLoadingBubbleState();
}

class _AiLoadingBubbleState extends State<_AiLoadingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primaryContainer,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _animController,
                  child: Text(
                    'AI sedang mengetik',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
