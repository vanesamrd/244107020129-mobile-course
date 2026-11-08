// lib/features/notes/presentation/widgets/empty_state_widget.dart
// Beautiful animated empty state.

import 'package:flutter/material.dart';

class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({super.key, required this.query, this.onClearSearch});
  final String query;
  final VoidCallback? onClearSearch;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSearching = widget.query.trim().isNotEmpty;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          key: const Key('empty_state'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSearching
                        ? Icons.manage_search_rounded
                        : Icons.sticky_note_2_outlined,
                    size: 56,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  isSearching ? 'Tidak Ditemukan' : 'Belum Ada Catatan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isSearching
                      ? 'Tidak ada catatan dengan judul\n"${widget.query}"'
                      : 'Tap tombol + Tambah Catatan\nuntuk membuat catatan pertamamu!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                if (isSearching) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: widget.onClearSearch,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Hapus Pencarian'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
