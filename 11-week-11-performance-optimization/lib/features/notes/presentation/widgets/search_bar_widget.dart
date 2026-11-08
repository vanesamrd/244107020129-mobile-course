// lib/features/notes/presentation/widgets/search_bar_widget.dart
// Modern Material 3 search bar with rounded styling.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notes_provider.dart';

class NoteSearchBar extends ConsumerStatefulWidget {
  const NoteSearchBar({super.key});

  @override
  ConsumerState<NoteSearchBar> createState() => _NoteSearchBarState();
}

class _NoteSearchBarState extends ConsumerState<NoteSearchBar> {
  static const _debounceDuration = Duration(milliseconds: 250);

  late final TextEditingController _controller;
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    _hasText.value = _controller.text.isNotEmpty;
    _controller.addListener(_syncHasText);
  }

  void _syncHasText() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText.value != hasText) {
      _hasText.value = hasText;
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_syncHasText);
    _controller.dispose();
    _hasText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    ref.listen<String>(searchQueryProvider, (previous, next) {
      if (next == _controller.text) return;
      _debounce?.cancel();
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _hasText,
        builder: (context, hasText, _) {
          return TextField(
            key: const Key('search_field'),
            controller: _controller,
            style: TextStyle(color: cs.onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Cari judul catatan…',
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: cs.onSurfaceVariant,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: _onSearchChanged,
          );
        },
      ),
    );
  }
}
