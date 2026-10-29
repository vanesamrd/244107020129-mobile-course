// lib/features/notes/presentation/notes_screen.dart
// Main screen – premium UI with gradient header, animated FAB, bottom sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notes_provider.dart';
import 'widgets/add_note_sheet.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/note_card.dart';
import 'widgets/search_bar_widget.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredNotesProvider);
    final allAsync = ref.watch(notesProvider);
    final query = ref.watch(searchQueryProvider);
    final cs = Theme.of(context).colorScheme;

    final totalNotes = allAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: cs.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Saya',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    '$totalNotes catatan tersimpan',
                    style: TextStyle(
                      color: cs.onPrimary.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              background: _GradientHeader(cs: cs),
            ),
          ),

          // ── Search bar ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: NoteSearchBar(),
            ),
          ),

          // ── Result count chip (only when searching) ──────────────────────
          if (query.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: filteredAsync.maybeWhen(
                data: (notes) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${notes.length} hasil untuk "$query"',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

          // ── Notes list / empty state ─────────────────────────────────────
          filteredAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 12),
                    Text(
                      'Terjadi kesalahan',
                      style: TextStyle(color: cs.error),
                    ),
                    Text('$e', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            data: (notes) => notes.isEmpty
                ? SliverFillRemaining(
                    child: EmptyStateWidget(
                      query: query,
                      onClearSearch: () =>
                          ref.read(searchQueryProvider.notifier).state = '',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final note = notes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NoteCard(
                            note: note,
                            onDelete: () => ref
                                .read(notesProvider.notifier)
                                .deleteNote(note.id),
                          ),
                        );
                      }, childCount: notes.length),
                    ),
                  ),
          ),
        ],
      ),

      // ── Floating Action Button ───────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Tambah Catatan'),
        elevation: 4,
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddNoteSheet(
        onSave: (title, body, color) {
          ref
              .read(notesProvider.notifier)
              .addNote(title: title, body: body, color: color);
        },
      ),
    );
  }
}

// ── Gradient background for SliverAppBar ─────────────────────────────────────
class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary],
        ),
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.onPrimary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.onPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
