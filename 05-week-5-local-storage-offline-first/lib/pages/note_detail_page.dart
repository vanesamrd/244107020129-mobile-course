import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../providers/note_provider.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  const NoteDetailPage({super.key, required this.noteId});
  final int noteId;

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  Note? _note;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(noteRepositoryProvider);
    final notes = await repo.fetchNotes();
    final note = notes.where((n) => n.id == widget.noteId).firstOrNull;
    if (!mounted) return;
    setState(() {
      _note = note;
      _titleController.text = note?.title ?? '';
      _bodyController.text = note?.body ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final note = _note;
    if (note == null) return;
    await ref.read(noteRepositoryProvider).updateNote(
          note.copyWith(
            title: _titleController.text,
            body: _bodyController.text,
          ),
        );
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    await ref.read(noteRepositoryProvider).deleteNote(widget.noteId);
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Hapus',
            onPressed: _delete,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Simpan',
            onPressed: _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _note == null
              ? const Center(child: Text('Catatan tidak ditemukan'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _bodyController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            labelText: 'Isi',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}