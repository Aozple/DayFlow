import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Compact note display for timeline view
class HomeNoteBlock extends StatelessWidget {
  final TaskModel note;
  final Function(TaskModel) onOptions;

  const HomeNoteBlock({super.key, required this.note, required this.onOptions});

  @override
  Widget build(BuildContext context) {
    final noteColor = AppColors.fromHex(note.color);

    return GestureDetector(
      onLongPress: () => onOptions(note),
      onTap: () => context.push('/edit-note', extra: note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: noteColor.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: noteColor.withAlpha(150), width: 1),
        ),
        child: Row(
          children: [
            // Note icon
            Icon(CupertinoIcons.doc_text_fill, size: 20, color: noteColor),
            const SizedBox(width: 12),
            // Note content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note title
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Note content preview
                  if (note.markdownContent?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      note.markdownContent!.replaceAll('\n', ' '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
