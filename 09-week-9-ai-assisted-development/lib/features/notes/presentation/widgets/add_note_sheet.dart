// lib/features/notes/presentation/widgets/add_note_sheet.dart
// Bottom sheet with color picker for adding notes.

import 'package:flutter/material.dart';

import '../../domain/note.dart';
import 'note_card.dart';

class AddNoteSheet extends StatefulWidget {
  const AddNoteSheet({super.key, required this.onSave});

  final void Function(String title, String body, NoteColor color) onSave;

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  NoteColor _selectedColor = NoteColor.purple;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _selectedColor.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Catatan Baru',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _selectedColor.text,
              ),
            ),
            const SizedBox(height: 16),

            // Title field
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _selectedColor.text,
              ),
              decoration: InputDecoration(
                hintText: 'Judul catatan…',
                hintStyle: TextStyle(
                  color: _selectedColor.text.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
              ),
            ),

            Divider(color: _selectedColor.accent.withValues(alpha: 0.3)),
            const SizedBox(height: 8),

            // Body field
            TextField(
              controller: _bodyCtrl,
              maxLines: 5,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: _selectedColor.text.withValues(alpha: 0.85),
              ),
              decoration: InputDecoration(
                hintText: 'Tulis isi catatan di sini…',
                hintStyle: TextStyle(
                  color: _selectedColor.text.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            Text(
              'Warna catatan',
              style: TextStyle(
                fontSize: 12,
                color: _selectedColor.text.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: NoteColor.values.map((c) {
                final isSelected = c == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    width: isSelected ? 36 : 30,
                    height: isSelected ? 36 : 30,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: c.accent.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _selectedColor.accent),
                      foregroundColor: _selectedColor.accent,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedColor.accent,
                    ),
                    onPressed: () {
                      if (_titleCtrl.text.trim().isNotEmpty) {
                        widget.onSave(
                          _titleCtrl.text,
                          _bodyCtrl.text,
                          _selectedColor,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
