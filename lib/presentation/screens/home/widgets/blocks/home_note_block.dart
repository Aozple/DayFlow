import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/app_color_utils.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class HomeNoteBlock extends StatelessWidget {
  final TaskModel note;
  final Function(TaskModel) onOptions;

  const HomeNoteBlock({super.key, required this.note, required this.onOptions});

  @override
  Widget build(BuildContext context) {
    final isDefaultColor = note.color == '#2C2C2E' || note.color == '#8E8E93';
    final noteColor =
        isDefaultColor
            ? Theme.of(context).colorScheme.primary
            : AppColorUtils.fromHex(note.color);

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        decoration: BoxDecoration(
          color: noteColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Icon(CupertinoIcons.ellipsis, color: noteColor),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          onOptions(note);
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => context.push('/edit-note', extra: note),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _buildContainerDecoration(noteColor, isDefaultColor),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildMainContent(noteColor, isDefaultColor)),
              const SizedBox(width: 8),
              _buildNoteTypeIndicator(noteColor, isDefaultColor),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(
    Color noteColor,
    bool isDefaultColor,
  ) {
    Color backgroundColor;

    if (isDefaultColor) {
      backgroundColor = AppColors.surfaceLight;
    } else {
      backgroundColor = noteColor.withAlpha(20);
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: noteColor, width: 2),
      boxShadow: [
        BoxShadow(
          color:
              isDefaultColor
                  ? Colors.black.withAlpha(10)
                  : noteColor.withAlpha(15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildMainContent(Color noteColor, bool isDefaultColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitleRow(noteColor, isDefaultColor),
        if (note.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildTagsRow(noteColor, isDefaultColor),
        ],
        if (_shouldShowPreview()) ...[
          const SizedBox(height: 8),
          _buildContentPreview(noteColor, isDefaultColor),
        ],
      ],
    );
  }

  Widget _buildTitleRow(Color noteColor, bool isDefaultColor) {
    final iconColor = isDefaultColor ? AppColors.textSecondary : noteColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(CupertinoIcons.doc_text_fill, size: 12, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            note.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow(Color noteColor, bool isDefaultColor) {
    final textColor =
        isDefaultColor ? AppColors.textTertiary : AppColors.textSecondary;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(note.tags.length, (index) {
          return Container(
            margin: EdgeInsets.only(
              right: index == note.tags.length - 1 ? 0 : 6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(60),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '# ${note.tags[index]}',
              style: TextStyle(
                fontSize: 10,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContentPreview(Color noteColor, bool isDefaultColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(60),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color:
                isDefaultColor
                    ? AppColors.textTertiary.withAlpha(100)
                    : noteColor.withAlpha(150),
            width: 2.5,
          ),
        ),
      ),
      child: Text(
        _cleanMarkdown(note.markdownContent!),
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          height: 1.3,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildNoteTypeIndicator(Color noteColor, bool isDefaultColor) {
    final iconColor = isDefaultColor ? AppColors.textSecondary : noteColor;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withAlpha(20),
        border: Border.all(color: iconColor.withAlpha(80), width: 1.5),
      ),
      child: Icon(CupertinoIcons.pencil, size: 18, color: iconColor),
    );
  }

  bool _shouldShowPreview() {
    return note.markdownContent?.isNotEmpty == true;
  }

  String _cleanMarkdown(String markdown) {
    return markdown
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*{1,3}|_{1,3}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(
          RegExp(r'```math|```|KATEX_INLINE_OPEN|KATEX_INLINE_CLOSE'),
          '',
        )
        .replaceAll(RegExp(r'[-*+]\s'), '')
        .replaceAll(RegExp(r'>\s'), '')
        .replaceAll('\n', ' ')
        .trim();
  }
}
