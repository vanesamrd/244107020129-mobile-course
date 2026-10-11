import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';

class NotesList extends StatelessWidget {
  final List<Note> notes;

  const NotesList(this.notes, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(title: Text(note.title), subtitle: Text(note.body));
      },
    );
  }
}
