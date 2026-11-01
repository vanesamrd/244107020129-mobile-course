// lib/features/notes/presentation/widgets/search_bar_widget.dart
// Modern Material 3 search bar with rounded styling.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notes_provider.dart';

class NoteSearchBar extends ConsumerStatefulWidget {
  const NoteSearchBar({super.key});

  @override
  ConsumerState<NoteSearchBar> createState() => _NoteSearchBarState();
}

class _NoteSearchBarState extends ConsumerState<NoteSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        key: const Key('search_field'),
        controller: _controller,
        style: TextStyle(color: cs.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Cari judul catatan…',
          hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.cancel_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
          setState(() {});
        },
      ),
    );
  }
}
