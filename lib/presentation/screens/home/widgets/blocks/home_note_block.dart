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
    // Determine color scheme
    final isDefaultColor = note.color == '#2C2C2E' || note.color == '#8E8E93';
    final noteColor =
        isDefaultColor
            ? AppColors.textSecondary
            : AppColors.fromHex(note.color);

    return GestureDetector(
      onLongPress: () => onOptions(note),
      onTap: () => context.push('/edit-note', extra: note),
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDefaultColor
                    ? [
                      AppColors.surfaceLight,
                      AppColors.surfaceLight.withAlpha(200),
                    ]
                    : [noteColor.withAlpha(25), noteColor.withAlpha(15)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDefaultColor
                    ? AppColors.divider.withAlpha(50)
                    : noteColor.withAlpha(80),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDefaultColor
                      ? AppColors.background.withAlpha(20)
                      : noteColor.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Options button
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => onOptions(note),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Note content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Note title with icon
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_fill,
                        size: 14,
                        color:
                            isDefaultColor
                                ? AppColors.textSecondary
                                : noteColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            height: 1.35,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Note content preview
                  if (note.markdownContent?.isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 8,
                        top: 4,
                        bottom: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withAlpha(60),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color:
                                isDefaultColor
                                    ? AppColors.accent.withAlpha(100)
                                    : noteColor.withAlpha(150),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _cleanMarkdown(note.markdownContent!),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  // Tags if any
                  if (note.tags.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.number,
                          size: 11,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note.tags.first,
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (note.tags.length > 1) ...[
                          Text(
                            ' +${note.tags.length - 1}',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Note type indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDefaultColor
                          ? [AppColors.surfaceLight, AppColors.surface]
                          : [noteColor.withAlpha(30), noteColor.withAlpha(20)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDefaultColor
                          ? AppColors.divider.withAlpha(50)
                          : noteColor.withAlpha(60),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDefaultColor
                            ? AppColors.background.withAlpha(20)
                            : noteColor.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 18,
                  color: isDefaultColor ? AppColors.textSecondary : noteColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanMarkdown(String markdown) {
    // Remove markdown syntax for preview
    return markdown
        .replaceAll(RegExp(r'#{1,6}\s'), '') // Headers
        .replaceAll(RegExp(r'\*{1,3}'), '') // Bold/Italic
        .replaceAll(RegExp(r'`{1,3}'), '') // Code
        .replaceAll(
          RegExp(r'```math|```|KATEX_INLINE_OPEN|KATEX_INLINE_CLOSE'),
          '',
        ) // Links
        .replaceAll(RegExp(r'[-*+]\s'), '') // Lists
        .replaceAll(RegExp(r'>\s'), '') // Quotes
        .replaceAll('\n', ' ')
        .trim();
  }
}
