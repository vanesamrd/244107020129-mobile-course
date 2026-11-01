// lib/features/notes/presentation/widgets/note_card.dart
// Premium card with color accent, tap ripple, slide-to-delete.

import 'package:flutter/material.dart';

import '../../domain/note.dart';

// Palette per NoteColor
extension NoteColorTheme on NoteColor {
  Color get background {
    return switch (this) {
      NoteColor.purple => const Color(0xFFF3EEFF),
      NoteColor.blue => const Color(0xFFE8F4FF),
      NoteColor.green => const Color(0xFFE8F5E9),
      NoteColor.orange => const Color(0xFFFFF3E0),
      NoteColor.pink => const Color(0xFFFCE4EC),
      NoteColor.yellow => const Color(0xFFFFFDE7),
    };
  }

  Color get accent {
    return switch (this) {
      NoteColor.purple => const Color(0xFF6750A4),
      NoteColor.blue => const Color(0xFF1565C0),
      NoteColor.green => const Color(0xFF2E7D32),
      NoteColor.orange => const Color(0xFFE65100),
      NoteColor.pink => const Color(0xFFC2185B),
      NoteColor.yellow => const Color(0xFFF57F17),
    };
  }

  Color get text {
    return switch (this) {
      NoteColor.purple => const Color(0xFF21005D),
      NoteColor.blue => const Color(0xFF003366),
      NoteColor.green => const Color(0xFF1B5E20),
      NoteColor.orange => const Color(0xFF4E2800),
      NoteColor.pink => const Color(0xFF4A0024),
      NoteColor.yellow => const Color(0xFF4A3700),
    };
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, required this.onDelete});

  final Note note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bg = note.color.background;
    final accent = note.color.accent;
    final textColor = note.color.text;

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDate(note.createdAt),
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Body preview
                  if (note.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      note.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.75),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Footer: delete hint
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.swipe_left_alt_rounded,
                        size: 14,
                        color: accent.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Geser kiri untuk hapus',
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            'Hapus',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
