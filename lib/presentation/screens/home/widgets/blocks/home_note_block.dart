import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Compact note display widget optimized for timeline view.
///
/// Provides an efficient and visually appealing interface for displaying
/// notes with content preview, tags, and quick access to options while
/// maintaining minimal space usage.
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
      onTap: () => context.push('/edit-note', extra: note),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _buildContainerDecoration(noteColor, isDefaultColor),
        child: Row(
          children: [
            // Color indicator
            _buildColorIndicator(noteColor, isDefaultColor),
            const SizedBox(width: 12),
            // Main content
            Expanded(child: _buildMainContent(noteColor, isDefaultColor)),
            const SizedBox(width: 8),
            // Options button as vertical dots
            _buildVerticalOptionsButton(noteColor, isDefaultColor),
            const SizedBox(width: 8),
            // Note type indicator
            _buildNoteTypeIndicator(noteColor, isDefaultColor),
          ],
        ),
      ),
    );
  }

  /// Build container decoration with gradient background
  BoxDecoration _buildContainerDecoration(
    Color noteColor,
    bool isDefaultColor,
  ) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            isDefaultColor
                ? [
                  AppColors.surfaceLight,
                  AppColors.surfaceLight.withAlpha(200),
                ]
                : [noteColor.withAlpha(20), noteColor.withAlpha(10)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color:
            isDefaultColor
                ? AppColors.divider.withAlpha(50)
                : noteColor.withAlpha(60),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color:
              isDefaultColor
                  ? AppColors.background.withAlpha(20)
                  : noteColor.withAlpha(15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Build vertical options button with three dots
  Widget _buildVerticalOptionsButton(Color noteColor, bool isDefaultColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onOptions(note);
      },
      child: Container(
        width: 20,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(
              isDefaultColor
                  ? AppColors.info.withAlpha(120)
                  : noteColor.withAlpha(120),
            ),
            const SizedBox(height: 4),
            _buildDot(
              isDefaultColor
                  ? AppColors.info.withAlpha(120)
                  : noteColor.withAlpha(120),
            ),
            const SizedBox(height: 4),
            _buildDot(
              isDefaultColor
                  ? AppColors.info.withAlpha(120)
                  : noteColor.withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }

  /// Build single dot for options button
  Widget _buildDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// Build color indicator with gradient effect
  Widget _buildColorIndicator(Color noteColor, bool isDefaultColor) {
    return Container(
      width: 4,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDefaultColor
                  ? [
                    AppColors.info.withAlpha(100),
                    AppColors.info.withAlpha(60),
                  ]
                  : [noteColor, noteColor.withAlpha(150)],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Build main content area with title, preview, and metadata
  Widget _buildMainContent(Color noteColor, bool isDefaultColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title row with note icon
        _buildTitleRow(noteColor, isDefaultColor),
        // Content preview
        if (_shouldShowPreview()) ...[
          const SizedBox(height: 6),
          _buildContentPreview(noteColor, isDefaultColor),
        ],
        // Tags
        if (note.tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildTagsRow(noteColor),
        ],
      ],
    );
  }

  /// Build title row with note type badge
  Widget _buildTitleRow(Color noteColor, bool isDefaultColor) {
    return Row(
      children: [
        // Note type badge
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:
                isDefaultColor
                    ? AppColors.info.withAlpha(15)
                    : noteColor.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            CupertinoIcons.doc_text_fill,
            size: 10,
            color: isDefaultColor ? AppColors.info : noteColor,
          ),
        ),
        const SizedBox(width: 8),
        // Title
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

  /// Build content preview with cleaned markdown
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
                    ? AppColors.info.withAlpha(100)
                    : noteColor.withAlpha(150),
            width: 2,
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

  /// Build tags row with count and preview
  Widget _buildTagsRow(Color noteColor) {
    return Row(
      children: [
        // Tags count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: noteColor.withAlpha(10),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '#${note.tags.length}',
            style: TextStyle(
              color: noteColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // First tag preview
        Flexible(
          child: Text(
            note.tags.first,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Additional tags count
        if (note.tags.length > 1) ...[
          Text(
            ' +${note.tags.length - 1}',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Build note type indicator with icon
  Widget _buildNoteTypeIndicator(Color noteColor, bool isDefaultColor) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDefaultColor
                  ? [AppColors.info.withAlpha(20), AppColors.info.withAlpha(10)]
                  : [noteColor.withAlpha(30), noteColor.withAlpha(20)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDefaultColor
                  ? AppColors.info.withAlpha(40)
                  : noteColor.withAlpha(60),
          width: 1,
        ),
      ),
      child: Icon(
        CupertinoIcons.pencil,
        size: 16,
        color: isDefaultColor ? AppColors.info : noteColor,
      ),
    );
  }

  /// Check if content preview should be displayed
  bool _shouldShowPreview() {
    return note.markdownContent?.isNotEmpty == true;
  }

  /// Clean markdown content for preview display
  String _cleanMarkdown(String markdown) {
    return markdown
        .replaceAll(RegExp(r'#{1,6}\s'), '') // Remove headers
        .replaceAll(RegExp(r'\*{1,3}'), '') // Remove bold/italic
        .replaceAll(RegExp(r'`{1,3}'), '') // Remove code formatting
        .replaceAll(
          RegExp(r'```math|```|KATEX_INLINE_OPEN|KATEX_INLINE_CLOSE'),
          '',
        ) // Remove math/code blocks
        .replaceAll(RegExp(r'[-*+]\s'), '') // Remove list markers
        .replaceAll(RegExp(r'>\s'), '') // Remove blockquotes
        .replaceAll('\n', ' ') // Replace newlines with spaces
        .trim();
  }
}
