import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// A compact display block for a note in the timeline.
///
/// This widget displays a note in a compact format suitable for the timeline view,
/// showing the note title and a preview of its content. It provides interactions
/// for editing the note and accessing options.
class HomeNoteBlock extends StatelessWidget {
  /// The note to display.
  final TaskModel note;

  /// Callback function to show note options.
  final Function(TaskModel) onOptions;

  const HomeNoteBlock({super.key, required this.note, required this.onOptions});

  @override
  Widget build(BuildContext context) {
    final noteColor = AppColors.fromHex(
      note.color,
    ); // Get the color from the note's hex string.

    return GestureDetector(
      onLongPress: () => onOptions(note), // Show options menu on long press.
      onTap:
          () => context.push(
            '/edit-note',
            extra: note,
          ), // Navigate to edit note screen on tap.
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ), // Space below each note block.
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: noteColor.withAlpha(
            40,
          ), // Semi-transparent background with note's color.
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: noteColor.withAlpha(150),
            width: 1,
          ), // Border with note's color.
        ),
        child: Row(
          children: [
            // Note icon.
            Icon(CupertinoIcons.doc_text_fill, size: 20, color: noteColor),
            const SizedBox(width: 12),
            // Note title and content preview.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Truncate long titles.
                  ),
                  // Show a preview of the markdown content if it exists.
                  if (note.markdownContent?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      note.markdownContent!.replaceAll(
                        '\n',
                        ' ',
                      ), // Replace newlines for single-line preview.
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Truncate long content.
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
