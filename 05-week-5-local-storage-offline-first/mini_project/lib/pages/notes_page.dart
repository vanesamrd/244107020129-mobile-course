import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/sync.dart';
import '../providers/connectivity_provider.dart';
import '../providers/note_provider.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          dirtyCount.when(
            data: (c) => c > 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Chip(
                        label: Text('$c belum sync'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync',
            onPressed: () async {
              if (isOffline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mode offline aktif. Sync tidak dapat dilakukan.',
                    ),
                  ),
                );
                return;
              }
              final repo = ref.read(noteRepositoryProvider);
              final count = await syncNotes(repo);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    count == 0
                        ? 'Tidak ada catatan yang perlu disinkronkan'
                        : '$count catatan berhasil disinkronkan',
                  ),
                ),
              );
              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: notes.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada catatan.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => NoteTile(note: items[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final repo = ref.read(noteRepositoryProvider);
          await repo.addNote(title: 'Catatan baru');
          ref.invalidate(notesProvider);
          ref.invalidate(dirtyCountProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Hasil refactoring: baris catatan diekstrak jadi widget tersendiri
/// dengan badge "belum tersinkron" bila dirty == true.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(
        note.body.isEmpty ? '—' : note.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: note.dirty
          ? const Chip(
              label: Text('belum tersinkron'),
              visualDensity: VisualDensity.compact,
            )
          : null,
      onTap: () => context.push('/note/${note.id}'),
    );
  }
}